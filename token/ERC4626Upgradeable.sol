// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @dev СТАТУС: БАНДЛ / базовая заготовка.
/// @dev Это относится к тому, что на соревнованиях, вероятно, дадут или дадут очень похожим по смыслу.

import {IERC4626} from "../interfaces/IERC4626.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {ERC20Upgradeable} from "./ERC20Upgradeable.sol";

/// @dev Бандл/заготовка ERC4626 для shares Vault.
/// @dev По сообщениям экспертов именно ERC4626 относится к числу предоставляемых базовых блоков.

/// @title Локальная реализация ERC4626
/// @notice Используется для shares Vault
abstract contract ERC4626Upgradeable is ERC20Upgradeable, IERC4626 {


    /// @dev Базовый токен хранилища.
    IERC20 private _asset;

    /// @dev Инициализация ERC4626.
    function __ERC4626_init(
        address asset_,
        string memory name_,
        string memory symbol_
    ) internal {
        require(asset_ != address(0), "ZERO_ASSET");
        __ERC20_init(name_, symbol_, 6);
        _asset = IERC20(asset_);
    }

    function asset() public view returns (address) {
        return address(_asset);
    }

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets_) public view returns (uint256) {
        uint256 supply = this.totalSupply();
        uint256 assetsTotal = totalAssets();

        // Для пустого Vault стартуем 1:1.
        if (supply == 0 || assetsTotal == 0) {
            return assets_;
        }

        return (assets_ * supply) / assetsTotal;
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = this.totalSupply();
        uint256 assetsTotal = totalAssets();

        // Для пустого Vault стартуем 1:1.
        if (supply == 0 || assetsTotal == 0) {
            return shares;
        }

        return (shares * assetsTotal) / supply;
    }

    function deposit(uint256 assets_, address receiver) public virtual returns (uint256 shares) {
        require(assets_ > 0, "ZERO_ASSETS");

        shares = convertToShares(assets_);
        require(shares > 0, "ZERO_SHARES");

        _asset.transferFrom(msg.sender, address(this), assets_);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets_, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets_) {
        require(shares > 0, "ZERO_SHARES");

        assets_ = convertToAssets(shares);
        require(assets_ > 0, "ZERO_ASSETS");

        _asset.transferFrom(msg.sender, address(this), assets_);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets_, shares);
    }

    function withdraw(uint256 assets_, address receiver, address owner) public virtual returns (uint256 shares) {
        require(assets_ > 0, "ZERO_ASSETS");

        // Округление вверх, чтобы точно сжечь достаточно shares.
        shares = convertToShares(assets_);
        if (convertToAssets(shares) < assets_) {
            shares += 1;
        }

        if (owner != msg.sender) {
            uint256 allowed = allowance(owner, msg.sender);
            require(allowed >= shares, "INSUFFICIENT_ALLOWANCE");
            if (allowed != type(uint256).max) {
                _approve(owner, msg.sender, allowed - shares);
            }
        }

        _burn(owner, shares);
        _asset.transfer(receiver, assets_);

        emit Withdraw(msg.sender, receiver, owner, assets_, shares);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256 assets_) {
        require(shares > 0, "ZERO_SHARES");

        assets_ = convertToAssets(shares);

        if (owner != msg.sender) {
            uint256 allowed = allowance(owner, msg.sender);
            require(allowed >= shares, "INSUFFICIENT_ALLOWANCE");
            if (allowed != type(uint256).max) {
                _approve(owner, msg.sender, allowed - shares);
            }
        }

        _burn(owner, shares);
        _asset.transfer(receiver, assets_);

        emit Withdraw(msg.sender, receiver, owner, assets_, shares);
    }
}
