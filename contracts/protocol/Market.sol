// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @dev СТАТУС: ПИШУ САМА.

import {IERC20} from "../interfaces/IERC20.sol";
import {IERC20Meta} from "../interfaces/IERC20Meta.sol";
import {IMarket} from "../interfaces/IMarket.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {Ownable} from "../acess/Ownable.sol";

contract Market is Ownable, IMarket {
    uint public constant INDEX_SCALE = 1e18;
    address[] public borrowers;

    struct Position {
        uint borrowShares;
        uint collateralShares;
        uint principal;
    }

    struct InitParams {
        address owner;
        address vault;
        address liquidator;
        address treasury;
        address loanToken;
        address collateralToken;
        address oracle;
        uint lltvBps;
        uint interestRate;
        uint blocksPerYear;
        uint liquidationBonusBps;
    }

    IERC20 public loanToken;
    IERC20 public collateralToken;
    IOracle public oracle;

    string public title;
    string public shareName;

    address public vault;
    address public treasury;
    address public liquidator;

    uint public lltvBps;
    uint public interestRate;
    uint public blocksPerYear;
    uint public liquidationBonusBps;
    uint public protocolReserves;
    uint public protocolFeeBps;
    uint public totalBorrowShares;
    uint public borrowIndex;
    uint public lastAccrueBlock;

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

    function initialize(
        InitParams calldata p,
        string calldata title_,
        string calldata shareName_
    ) external initializer {
        __Ownable_init(p.owner);

        title = title_;
        shareName = shareName_;

        loanToken = IERC20(p.loanToken);
        collateralToken = IERC20(p.collateralToken);
        oracle = IOracle(p.oracle);

        liquidator = p.liquidator;
        treasury = p.treasury;
        vault = p.vault;

        interestRate = p.interestRate;
        lltvBps = p.lltvBps;
        protocolFeeBps = 3000;
        borrowIndex = INDEX_SCALE;
        blocksPerYear = p.blocksPerYear;
        lastAccrueBlock = block.number;
        liquidationBonusBps = p.liquidationBonusBps;
    }

    function accrueInterest() public {
        if (block.number == lastAccrueBlock) return;
        if (totalBorrowShares > 0) {
            uint deltaBlocks = block.number - lastAccrueBlock;
            uint growth = (interestRate * deltaBlocks) / INDEX_SCALE;
            borrowIndex += (borrowIndex * growth) / INDEX_SCALE;
        }
        lastAccrueBlock = block.number;
    }

    function availableLiquidity() public view returns (uint) {
        uint bal = oracle.getPrice(address(loanToken));
        return bal <= protocolReserves ? 0 : bal - protocolReserves;
    }

    function _projectedBorrowIndex() internal view returns (uint index) {
        index = borrowIndex;
        if (block.number == lastAccrueBlock && totalBorrowShares > 0) {
            uint deltaBlocks = block.number - lastAccrueBlock;
            uint growth = (interestRate * deltaBlocks) / INDEX_SCALE;
            index += (index * growth) / INDEX_SCALE;
        }
    }

    function _sharesForBorrowAmount(
        uint amount
    ) internal view returns (uint shares) {
        shares = (amount * INDEX_SCALE) / borrowIndex;
        if (shares == 0) shares = 1;
    }

    function _isHealthy(address borrower) internal view returns (bool) {
        return currentLtvBps(borrower) < lltvBps;
    }

    function totalDebt() public view returns (uint) {
        return
            totalBorrowShares == 0
                ? 0
                : (totalBorrowShares * _projectedBorrowIndex()) / INDEX_SCALE;
    }

    function debtOf(address borrower) public view returns (uint) {
        uint shares = positions[borrower].borrowShares;
        return
            shares == 0 ? 0 : (shares * _projectedBorrowIndex()) / INDEX_SCALE;
    }

    function assetManage() public view returns (uint) {
        return availableLiquidity() + totalDebt();
    }

    function currentLtvBps(address borrower) public view returns (uint) {
        Position storage p = positions[borrower];
        uint debt = debtOf(borrower);

        if (debt == 0) return 0;
        if (p.collateralShares == 0) return type(uint).max;

        return
            (debt * oracle.getPrice(address(loanToken)) * 10000) /
            (p.collateralShares * oracle.getPrice(address(collateralToken)));
    }

    function supplyCollateral(uint amount) external {
        require(amount > 0);

        collateralToken.transferFrom(msg.sender, address(this), amount);
        positions[msg.sender].collateralShares += amount;
    }

    function withdrawCollateral(uint amount) external {
        require(amount > 0);
        Position storage p = positions[msg.sender];

        p.collateralShares -= amount;
        require(_isHealthy(msg.sender));
        collateralToken.transfer(msg.sender, amount);
    }

    function healthFactor(address borrower) public view returns (uint) {
        uint ltv = currentLtvBps(borrower);
        if (ltv == 0) return type(uint).max;
        return (lltvBps * INDEX_SCALE) / ltv;
    }

    function borrow(uint amount) external {
        accrueInterest();

        Position storage p = positions[msg.sender];

        uint shares = _sharesForBorrowAmount(amount);
        p.borrowShares += shares;
        totalBorrowShares += shares;
        p.principal += shares;

        loanToken.transfer(msg.sender, amount);
        borrowers.push(msg.sender);
    }

    function repay(uint amount) external returns (uint remainingDebt) {
        accrueInterest();

        Position storage p = positions[msg.sender];
        uint debt = debtOf(msg.sender);

        uint payAmount = amount > debt ? debt : amount;
        loanToken.transferFrom(msg.sender, address(this), amount);

        uint principalPaid = p.principal > payAmount ? payAmount : p.principal;
        p.principal -= principalPaid;
        protocolReserves +=
            ((payAmount - principalPaid) * protocolFeeBps) / 10000;
        uint burnShares = payAmount == debt
            ? p.borrowShares
            : (payAmount * INDEX_SCALE) / borrowIndex;

        if (burnShares < p.borrowShares) burnShares = p.borrowShares;
        p.borrowShares -= burnShares;
        totalBorrowShares -= burnShares;
        remainingDebt = debtOf(msg.sender);
    }

    function liquidate(address borrower) external onlyLiquidatorOrOwner {
        accrueInterest();

        Position storage p = positions[borrower];
        uint debt = debtOf(borrower);

        uint reward = (p.collateralShares * liquidationBonusBps) / 10000;
        uint remainder = p.collateralShares - reward;

        require(!_isHealthy(borrower));
        loanToken.transfer(msg.sender, reward);
        loanToken.transfer(treasury, remainder);

        totalBorrowShares -= p.borrowShares;
        delete positions[borrower];
        borrowers.pop();
        emit Liquidated(borrower, msg.sender, debt, reward);
    }

    function onVaultDeposit(uint amount) external onlyVault {}

    function onVaultWithdraw(uint amount) external onlyVault {
        loanToken.transfer(vault, amount);
    }
    function setRiskParams(
        uint256 newLltvBps,
        uint256 newInterestRate,
        uint256 newLiquidationBonusBps
    ) external onlyOwner {
        require(newLltvBps <= 10000, "BAD_LLTV");
        require(newLiquidationBonusBps <= 10000, "BAD_LIQ_BONUS");
        accrueInterest();
        lltvBps = newLltvBps;
        interestRate = newInterestRate;
        liquidationBonusBps = newLiquidationBonusBps;
    }
}
