// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @dev СТАТУС: ПИШУ САМА.

import {ERC4626Upgradeable} from "../token/ERC4626Upgradeable.sol";
import {Ownable} from "../acess/Ownable.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IMarket} from "../interfaces/IMarket.sol";
import {UUPSUpgradeable} from "../proxy/UUPSUpgradeable.sol";

contract Vault is Ownable, ERC4626Upgradeable, UUPSUpgradeable {
    

    string public title;
    uint256 public apy;
    uint256 public minDeposit;
    address[] public markets;
    mapping(address => bool) public isMarket;

    function initialize(
        address owner_,
        address asset_,
        string calldata title_,
        string calldata shareName_,
        string calldata shareSymbol_,
        uint256 apy_,
        uint256 minDeposit_
    ) external initializer {
        __Ownable_init(owner_);
        __ERC4626_init(asset_, shareName_, shareSymbol_);
        title = title_;
        apy = apy_;
        minDeposit = minDeposit_;
    }

    function totalAssets() public view override returns (uint256 total) {
        total = IERC20(asset()).balanceOf(address(this));
        uint256 len = markets.length;
        for (uint256 i = 0; i < len; ) {
            if (isMarket[markets[i]]) total += IMarket(markets[i]).assetManage();
            unchecked {
                ++i;
            }
        }
    }

    function idleLiquidity() public view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function deposit(uint256 assets_, address receiver) public override returns (uint256 shares) {
        require(assets_ >= minDeposit, "DEPOSIT_TOO_SMALL");
        shares = super.deposit(assets_, receiver);
    }

    function withdraw(uint256 assets_, address receiver, address owner_) public override returns (uint256 shares) {
        require(assets_ <= idleLiquidity(), "NO_FREE_LIQUIDITY");
        shares = super.withdraw(assets_, receiver, owner_);
    }

    function allocateToMarket(address market_, uint256 amount) external onlyOwner {
        require(isMarket[market_], "UNKNOWN_MARKET");
        require(amount <= idleLiquidity(), "NO_FREE_LIQUIDITY");
        IERC20(asset()).transfer(market_, amount);
        IMarket(market_).onVaultDeposit(amount);
    }

    function deallocateFromMarket(address market_, uint256 amount) external onlyOwner {
        require(isMarket[market_], "UNKNOWN_MARKET");
        IMarket(market_).onVaultWithdraw(amount);
    }

    function addMarket(address market_) external onlyOwner {
        require(market_ != address(0), "ZERO_MARKET");
        require(!isMarket[market_], "MARKET_EXISTS");
        isMarket[market_] = true;
        markets.push(market_);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
