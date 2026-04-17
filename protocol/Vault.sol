// // SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "../interfaces/IERC20.sol";
import {UUPSUpgradeable} from "../proxy/UUPSUpgradeable.sol";
import {ERC4626Upgradeable} from "../token/ERC4626Upgradeable.sol";
import {Ownable} from "../acess/Ownable.sol";
import {IMarket} from "../interfaces/IMarket.sol";

contract Vault is Ownable, ERC4626Upgradeable, UUPSUpgradeable {
    string public title;
    uint public minDeposit;
    address[] public markets;
    mapping(address => bool) public isMarket;

    function initialize(
        address owner_,
        address asset_,
        string calldata title_,
        string calldata shareName_,
        string calldata shareSymbol_,
        uint minDeposit_
    ) external initializer {
        __Ownable_init(owner_);
        __ERC4626_init(asset_, shareName_, shareSymbol_);
        title = title_;
        minDeposit = minDeposit_;
    }

    function totalAssets() public override view returns (uint total) {
        total = IERC20(asset()).balanceOf(address(this));
        for (uint i = 0; i < markets.length; ) {
            if (isMarket[markets[i]]) total += IMarket(markets[i]).assetManage();
            unchecked {
                ++i;
            }
        }
    }

    function idleLiquidity() public view returns (uint) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function deposit(
        uint assets_,
        address receiver
    ) public override returns (uint shares) {
        require(assets_ <= idleLiquidity());
        shares = super.deposit(assets_, receiver);
    }

    function withdraw(
        uint assets_,
        address receiver,
        address owner_
    ) public override returns (uint shares) {
        require(assets_ <= idleLiquidity());
        shares = super.withdraw(assets_, receiver, owner_);
    }

    function allocateToMarket(address market_, uint amount) external onlyOwner {
        require(isMarket[market_]);
        require(amount <= idleLiquidity());
        IERC20(asset()).transfer(market_, amount);
        IMarket(market_).onVaultDeposit(amount);
    }
    function deallocateTomarket(
        address market_,
        uint amount
    ) external onlyOwner {
        require(isMarket[market_]);
        require(amount <= idleLiquidity());
        IMarket(market_).onVaultWithdraw(amount);
    }

    function addMarket(address market_) external onlyOwner {
        require(market_ != address(0));
        require(!isMarket[market_]);
        isMarket[market_] = true;
        markets.push(market_);
    }
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
