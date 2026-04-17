// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Интерфейс ERC20
/// @notice Локальная копия стандарта без внешних зависимостей
interface IERC20 {
    /// @dev Срабатывает при переводе токенов.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Срабатывает при изменении allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Общее количество токенов.
    function totalSupply() external view returns (uint256);

    /// @notice Баланс аккаунта.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Перевод токенов получателю.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Текущий allowance от owner к spender.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Установка allowance для spender.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Перевод токенов по allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
