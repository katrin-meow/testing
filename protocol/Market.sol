// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @dev СТАТУС: ПИШУ САМА.

import {IERC20} from "../interfaces/IERC20.sol";
import {IMarket} from "../interfaces/IMarket.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {Ownable} from "../acess/Ownable.sol";
import {UUPSUpgradeable} from "../proxy/UUPSUpgradeable.sol";

contract Market is Ownable, IMarket, UUPSUpgradeable {
    uint public constant INDEX_SCALE = 1e18;
    address[] public borrowers;

    struct Position {
        uint collateralShares;
        uint borrowShares;
        uint principal;
    }

    struct InitParams {
        address owner;
        address liquidator;
        address treasury;
        address loanToken;
        address collateralToken;
        address oracle;
        address vault;
        uint lltvBps;
        uint interestRate;
        uint blocksPerYear;
        uint liquidationBonusBps;
    }

    mapping(address => Position) public positions;

    modifier onlyVault() {
        require(msg.sender == vault);
        _;
    }

    modifier onlyLiquidatorOrOwner() {
        require(msg.sender == liquidator || msg.sender == owner);
        _;
    }

    event Liquidated(
        address indexed borrower,
        address indexed liquidator,
        uint debt,
        uint rewardCollateral
    );

    IERC20 public loanToken;
    IERC20 public collateralToken;
    IOracle public oracle;

    string public title;
    string public shareName;

    address public liquidator;
    address public vault;
    address public treasury;

    uint public lltvBps;
    uint public interestRate;
    uint public blocksPerYear;
    uint public liquidationBonusBps;
    uint public lastAccrueBlock;
    uint public borrowIndex;
    uint public protocolFeeBps;
    uint public protocolReserves;
    uint public totalBorrowShares;

    function initialize(
        InitParams calldata p,
        string calldata title_,
        string calldata shareName_
    ) external initializer {
        require(p.vault != address(0));
        require(p.loanToken != address(0));
        require(p.collateralToken != address(0));
        require(p.oracle != address(0));
        require(blocksPerYear > 0);
        require(p.liquidationBonusBps <= 10000);
        require(p.lltvBps <= 100000);

        __Ownable_init(p.owner);

        title = title_;
        shareName = shareName_;

        loanToken = IERC20(p.loanToken);
        collateralToken = IERC20(p.collateralToken);
        oracle = IOracle(p.oracle);

        vault = p.vault;
        treasury = p.treasury;
        liquidator = p.liquidator;

        lltvBps = p.lltvBps;
        lastAccrueBlock = block.number;
        blocksPerYear = p.blocksPerYear;
        interestRate = p.interestRate;
        borrowIndex = INDEX_SCALE;
        liquidationBonusBps = p.liquidationBonusBps;
        protocolFeeBps = 30000;
    }

    function accrueInterest() public {
        if (block.number == lastAccrueBlock) return;
        if (totalBorrowShares > 0) {
            uint deltaBlocks = block.number - lastAccrueBlock;
            uint growth = (interestRate * deltaBlocks) / blocksPerYear;
            borrowIndex = (borrowIndex * growth) / INDEX_SCALE;
        }
        lastAccrueBlock - block.number;
    }

    function availableLiquidity() public view returns (uint) {
        uint bal = loanToken.balanceOf(address(this));
        return bal <= protocolReserves ? 0 : bal - protocolReserves;
    }

    function _projectedBorrowIndex() internal view returns (uint index) {
        index = borrowIndex;
        if (block.number == lastAccrueBlock && totalBorrowShares > 0) {
            uint deltaBlocks = block.number - lastAccrueBlock;
            uint growth = (interestRate * deltaBlocks) / blocksPerYear;
            index = (index * growth) / INDEX_SCALE;
        }
    }

    function _sharesForBorrowAmount(
        uint amount
    ) public view returns (uint shares) {
        require(amount > 0);
        shares = (amount * INDEX_SCALE) / borrowIndex;
        if (shares == 0) shares = 1;
    }

    function _isHealthy(address borrower) public view returns (bool) {
        return currentLltvBps(borrower) < lltvBps;
    }

    function totalDebt() public view returns (uint) {
        return
            totalBorrowShares == 0
                ? 0
                : (totalBorrowShares * _projectedBorrowIndex()) / INDEX_SCALE;
    }

    function debtOf(address borrower) public view returns (uint) {
        require(borrower != address(0));

        uint shares = positions[borrower].borrowShares;
        return
            shares == 0 ? 0 : (shares * _projectedBorrowIndex()) / INDEX_SCALE;
    }

    function assetManage() public view returns (uint) {
        return availableLiquidity() + totalDebt();
    }

    function currentLltvBps(address borrower) public view returns (uint) {
        require(borrower != address(0));
        uint debt = debtOf(borrower);
        Position storage p = positions[borrower];
        if (debt == 0) return 0;
        if (p.collateralShares == 0) return type(uint).max;
        return
            (debt * oracle.getPrice(address(loanToken)) * 10000) /
            (p.collateralShares * oracle.getPrice(address(collateralToken)));
    }

    function supplyCollateral(uint amount) external {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        positions[msg.sender].collateralShares += amount;
    }

    function withdrawCollateral(uint amount) external {
        require(amount > 0);
        accrueInterest();

        Position storage p = positions[msg.sender];
        require(amount <= p.collateralShares);
        p.collateralShares -= amount;
        require(_isHealthy(msg.sender));
        collateralToken.transfer(msg.sender, amount);
    }

    function healthFactor(address borrower) public view returns (uint) {
        uint ltv = currentLltvBps(borrower);
        if (ltv == 0) return type(uint).max;
        return (lltvBps * INDEX_SCALE) / ltv;
    }

    function borrow(uint amount) external {
        require(amount > 0);
        accrueInterest();

        require(amount <= availableLiquidity());
        Position storage p = positions[msg.sender];
        uint shares = _sharesForBorrowAmount(amount);
        p.borrowShares += shares;
        p.principal += shares;
        totalBorrowShares += shares;
        require(_isHealthy(msg.sender));
        loanToken.transfer(msg.sender, amount);
        borrowers.push(msg.sender);
    }

    function repay(uint amount) external returns (uint remainingDebt) {
        require(amount > 0);
        accrueInterest();

        Position storage p = positions[msg.sender];
        uint debt = debtOf(msg.sender);
        require(debt > 0);
        uint payAmount = amount > debt ? debt : amount;
        loanToken.transferFrom(msg.sender, address(this), payAmount);

        uint principalPaid = p.principal > payAmount ? payAmount : p.principal;
        p.principal -= principalPaid;
        protocolFeeBps += ((payAmount - principalPaid) * protocolFeeBps) / 1000;

        uint burnShares = payAmount == debt
            ? p.borrowShares
            : (payAmount * INDEX_SCALE) / borrowIndex;

        if (burnShares > p.borrowShares) burnShares = p.borrowShares;
        p.borrowShares -= burnShares;
        totalBorrowShares -= burnShares;
        remainingDebt = debtOf(msg.sender);
    }

    function liquidate(address borrower) external onlyLiquidatorOrOwner {
        accrueInterest();
        require(!_isHealthy(borrower));

        Position storage p = positions[borrower];
        uint debt = debtOf(borrower);
        require(debt > 0);

        uint reward = (p.collateralShares * liquidationBonusBps) / 10000;
        uint remainder = p.collateralShares - reward;
        if (reward > 0) collateralToken.transfer(msg.sender, reward);
        if (remainder > 0) collateralToken.transfer(treasury, remainder);

        totalBorrowShares -= p.borrowShares;
        delete positions[borrower];
        borrowers.pop();

        emit Liquidated(borrower, msg.sender, debt, reward);
    }
    function onVaultDeposit(uint amount) external onlyVault {}

    function onVaultWithdraw(uint amount) external onlyVault {
        require(amount <= availableLiquidity());
        loanToken.transfer(msg.sender, amount);
    }

    function setRiskParams(
        uint newLltvBps,
        uint newInterestRate,
        uint newLiquidationBonusBps
    ) external onlyOwner {
        require(newLltvBps <= 10000);
        require(newLltvBps <= 10000);

        lltvBps = newLltvBps;
        interestRate = newInterestRate;
        liquidationBonusBps = newLiquidationBonusBps;
    }

    function setLiquidator(address newLiquidator) external onlyOwner {
        liquidator = newLiquidator;
    }

    function setTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
