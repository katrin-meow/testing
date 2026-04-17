// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @dev СТАТУС: ПИШУ САМА.

import {IERC20} from "../interfaces/IERC20.sol";
import {IERC20Meta} from "../interfaces/IERC20Meta.sol";
import {IMarket} from "../interfaces/IMarket.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {Ownable} from "../acess/Ownable.sol";
import {UUPSUpgradeable} from "../proxy/UUPSUpgradeable.sol";

contract Market is Ownable, IMarket, UUPSUpgradeable {


    uint256 public constant INDEX_SCALE = 1e18;

    struct Position {
        uint256 collateralShares;
        uint256 borrowShares;
        uint256 principal;
    }

    struct InitParams {
        address owner;
        address vault;
        address loanToken;
        address collateralToken;
        address oracle;
        address treasury;
        address liquidator;
        uint256 lltvBps;
        uint256 interestRate;
        uint256 blocksPerYear;
        uint256 liquidationBonusBps;
    }
//["0x71562b71999873DB5b286dF957af199Ec94617F7","0xcAb99AFdafCB2D9452f481017b94888E876EadB7","0x3CB5b6E26e0f37F2514D45641F15Bd6fEC2E0c4c","0x319b4b3b71398EABaDae47ccEA2e1e6be3e83056","0xD73F34428098B44A589f13Ad15A0e3D2eFE92DBD","0x71562b71999873DB5b286dF957af199Ec94617F7","0x71562b71999873DB5b286dF957af199Ec94617F7",8500,35000000000,2102400,2000]
    IERC20 public loanToken;
    IERC20 public collateralToken;
    IOracle public oracle;
    string public title;
    string public shareName;
    address public vault;
    address public treasury;
    address public liquidator;
    uint256 public lltvBps;
    uint256 public liquidationBonusBps;
    uint256 public protocolFeeBps;
    uint256 public interestRate;
    uint256 public blocksPerYear;
    uint256 public borrowIndex;
    uint256 public lastAccrueBlock;
    uint256 public totalBorrowShares;
    uint256 public protocolReserves;
    mapping(address => Position) public positions;

    event Liquidated(address indexed borrower, address indexed liquidator_, uint256 debt, uint256 rewardCollateral);

    modifier onlyVault() {
        require(msg.sender == vault, "NOT_VAULT");
        _;
    }

    modifier onlyLiquidatorOrOwner() {
        require(msg.sender == liquidator || msg.sender == owner, "NOT_LIQUIDATOR");
        _;
    }

    function initialize(InitParams calldata p, string calldata title_, string calldata shareName_) external initializer {
        require(p.vault != address(0), "ZERO_VAULT");
        require(p.loanToken != address(0), "ZERO_LOAN");
        require(p.collateralToken != address(0), "ZERO_COLLATERAL");
        require(p.oracle != address(0), "ZERO_ORACLE");
        require(p.treasury != address(0), "ZERO_TREASURY");
        require(p.blocksPerYear > 0, "ZERO_BPY");
        require(p.lltvBps <= 10000, "BAD_LLTV");
        require(p.liquidationBonusBps <= 10000, "BAD_LIQ_BONUS");
        __Ownable_init(p.owner);
        vault = p.vault;
        loanToken = IERC20(p.loanToken);
        collateralToken = IERC20(p.collateralToken);
        oracle = IOracle(p.oracle);
        treasury = p.treasury;
        liquidator = p.liquidator;
        title = title_;
        shareName = shareName_;
        lltvBps = p.lltvBps;
        interestRate = p.interestRate;
        blocksPerYear = p.blocksPerYear;
        liquidationBonusBps = p.liquidationBonusBps;
        protocolFeeBps = 3000;
        borrowIndex = INDEX_SCALE;
        lastAccrueBlock = block.number;
    }

    function accrueInterest() public {
        if (block.number == lastAccrueBlock) return;
        if (totalBorrowShares > 0) {
            uint256 deltaBlocks = block.number - lastAccrueBlock;
            uint256 growth = (interestRate * deltaBlocks) / blocksPerYear;
            borrowIndex += (borrowIndex * growth) / INDEX_SCALE;
        }
        lastAccrueBlock = block.number;
    }

    function availableLiquidity() public view returns (uint256) {
        uint256 bal = loanToken.balanceOf(address(this));
        return bal <= protocolReserves ? 0 : bal - protocolReserves;
    }

    function totalDebt() public view returns (uint256) {
        return totalBorrowShares == 0 ? 0 : (totalBorrowShares * _projectedBorrowIndex()) / INDEX_SCALE;
    }

    function assetManage() public view returns (uint256) {
        return availableLiquidity() + totalDebt();
    }

    function debtOf(address borrower) public view returns (uint256) {
        uint256 shares = positions[borrower].borrowShares;
        return shares == 0 ? 0 : (shares * _projectedBorrowIndex()) / INDEX_SCALE;
    }

    function currentLtvBps(address borrower) public view returns (uint256) {
        Position storage p = positions[borrower];
        uint256 debt = debtOf(borrower);
        if (debt == 0) return 0;
        if (p.collateralShares == 0) return type(uint256).max;
        uint256 debtValue = _tokenValue(debt, address(loanToken));
        uint256 collateralValue = _tokenValue(p.collateralShares, address(collateralToken));
        if (collateralValue == 0) return type(uint256).max;
        return (debtValue * 10000) / collateralValue;
    }

    function healthFactor(address borrower) public view returns (uint256) {
        uint256 ltv = currentLtvBps(borrower);
        if (ltv == 0) return type(uint256).max;
        return (lltvBps * INDEX_SCALE) / ltv;
    }

    function supplyCollateral(uint256 amount) external {
        require(amount > 0, "ZERO_AMOUNT");
        collateralToken.transferFrom(msg.sender, address(this), amount);
        positions[msg.sender].collateralShares += amount;
    }

    function withdrawCollateral(uint256 amount) external {
        require(amount > 0, "ZERO_AMOUNT");
        accrueInterest();
        Position storage p = positions[msg.sender];
        require(amount <= p.collateralShares, "EXCEEDS_COLLATERAL");
        p.collateralShares -= amount;
        require(_isHealthy(msg.sender), "WOULD_BE_LIQUIDATABLE");
        collateralToken.transfer(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        require(amount > 0, "ZERO_AMOUNT");
        accrueInterest();
        require(amount <= availableLiquidity(), "INSUFFICIENT_LIQUIDITY");
        Position storage p = positions[msg.sender];
        uint256 shares = _sharesForBorrowAmount(amount);
        p.borrowShares += shares;
        p.principal += amount;
        totalBorrowShares += shares;
        require(_isHealthy(msg.sender), "BORROW_BREAKS_LLTV");
        loanToken.transfer(msg.sender, amount);
    }

    function repay(uint256 amount) external returns (uint256 remainingDebt) {
        require(amount > 0, "ZERO_AMOUNT");
        accrueInterest();
        Position storage p = positions[msg.sender];
        uint256 debt = debtOf(msg.sender);
        require(debt > 0, "NO_DEBT");
        uint256 payAmount = amount > debt ? debt : amount;
        loanToken.transferFrom(msg.sender, address(this), payAmount);
        uint256 principalPaid = p.principal > payAmount ? payAmount : p.principal;
        p.principal -= principalPaid;
        protocolReserves += ((payAmount - principalPaid) * protocolFeeBps) / 10000;
        uint256 burnShares = payAmount == debt ? p.borrowShares : (payAmount * INDEX_SCALE) / borrowIndex;
        if (burnShares > p.borrowShares) burnShares = p.borrowShares;
        p.borrowShares -= burnShares;
        totalBorrowShares -= burnShares;
        remainingDebt = debtOf(msg.sender);
    }

    function liquidate(address borrower) external onlyLiquidatorOrOwner {
        accrueInterest();
        require(!_isHealthy(borrower), "POSITION_HEALTHY");
        Position storage p = positions[borrower];
        uint256 debt = debtOf(borrower);
        require(debt > 0, "NO_DEBT");
        uint256 reward = (p.collateralShares * liquidationBonusBps) / 10000;
        uint256 remainder = p.collateralShares - reward;
        if (reward > 0) collateralToken.transfer(msg.sender, reward);
        if (remainder > 0) collateralToken.transfer(treasury, remainder);
        totalBorrowShares -= p.borrowShares;
        delete positions[borrower];
        emit Liquidated(borrower, msg.sender, debt, reward);
    }

    function onVaultDeposit(uint256) external onlyVault {}

    function onVaultWithdraw(uint256 amount) external onlyVault {
        require(amount <= availableLiquidity(), "INSUFFICIENT_LIQUIDITY");
        loanToken.transfer(vault, amount);
    }

    function setRiskParams(uint256 newLltvBps, uint256 newInterestRate, uint256 newLiquidationBonusBps) external onlyOwner {
        require(newLltvBps <= 10000, "BAD_LLTV");
        require(newLiquidationBonusBps <= 10000, "BAD_LIQ_BONUS");
        accrueInterest();
        lltvBps = newLltvBps;
        interestRate = newInterestRate;
        liquidationBonusBps = newLiquidationBonusBps;
    }

    function _sharesForBorrowAmount(uint256 amount) internal view returns (uint256 shares) {
        shares = (amount * INDEX_SCALE) / borrowIndex;
        if (shares == 0) shares = 1;
    }

    function _isHealthy(address borrower) internal view returns (bool) {
        return currentLtvBps(borrower) < lltvBps;
    }

    function _projectedBorrowIndex() internal view returns (uint256 index) {
        index = borrowIndex;
        if (block.number > lastAccrueBlock && totalBorrowShares > 0) {
            uint256 deltaBlocks = block.number - lastAccrueBlock;
            uint256 growth = (interestRate * deltaBlocks) / blocksPerYear;
            index += (index * growth) / INDEX_SCALE;
        }
    }

    function _tokenValue(uint256 amount, address token) internal view returns (uint256) {
        uint8 decimals = IERC20Meta(token).decimals();
        return (amount * oracle.getPrice(token)) / (10 ** decimals);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
