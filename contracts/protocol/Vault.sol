// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @dev СТАТУС: ПИШУ САМА.

import {ERC4626Upgradeable} from "../token/ERC4626Upgradeable.sol";
import {Ownable} from "../acess/Ownable.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IMarket} from "../interfaces/IMarket.sol";

contract Vault is Ownable, ERC4626Upgradeable {
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

    function totalAssets() public view override returns (uint total) {
        total = IERC20(asset()).balanceOf(address(this));
        for (uint i = 0; i < markets.length; ) {
            if (isMarket[markets[i]])
                total += IMarket(markets[i]).assetManage();
            unchecked {
                ++i;
            }
        }
    }
    function idleLiquidity() public view returns (uint shares) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function deposit(
        uint assets_,
        address receiver
    ) public override returns (uint shares) {
        shares = super.deposit(assets_, receiver);
    }

    function withdraw(
        uint assets_,
        address receiver,
        address owner
    ) public override returns (uint shares) {
        shares = super.withdraw(assets_, receiver, owner);
    }

    function allocateToMarket(address market_, uint amount) external onlyOwner {
        IERC20(asset()).transfer(market_, amount);
        IMarket(market_).onVaultDeposit(amount);
    }

    function deallocateToMarket(
        address market_,
        uint amount
    ) external onlyOwner {
        IMarket(market_).onVaultWithdraw(amount);
    }

    function addMarket(address market_) external onlyOwner {
        isMarket[market_] = true;
        markets.push(market_);
    }
}
