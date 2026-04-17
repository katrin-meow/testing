// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Интерфейс ERC4626
/// @notice Нужен для shares волта
interface IERC4626 {
    /// @dev Событие при deposit/mint.
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    /// @dev Событие при withdraw/redeem.
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    /// @notice Адрес базового актива.
    function asset() external view returns (address);

    /// @notice Общие активы под управлением.
    function totalAssets() external view returns (uint256);

    /// @notice Конвертация активов в shares.
    function convertToShares(uint256 assets) external view returns (uint256);

    /// @notice Конвертация shares в активы.
    function convertToAssets(uint256 shares) external view returns (uint256);

    /// @notice Депозит активов с выпуском shares.
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /// @notice Выпуск shares за соответствующее количество активов.
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /// @notice Вывод активов с сжиганием shares.
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /// @notice Погашение shares в актив.
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}
