// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @dev СТАТУС: БАНДЛ / базовая заготовка.
/// @dev Это относится к тому, что на соревнованиях, вероятно, дадут или дадут очень похожим по смыслу.

import {IERC20Meta} from "../interfaces/IERC20Meta.sol";
import {Init} from "../utils/Init.sol";

/// @dev Бандл/заготовка ERC20, которую важно уметь использовать на соревнованиях.
/// @dev Не обязательно совпадет побайтно с выданной, но по смыслу это тот же строительный блок.

/// @title Локальная реализация ERC20 (upgradable-стиль)
contract ERC20Upgradeable is Init, IERC20Meta {
    /// @dev Метаданные токена.
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /// @dev Базовое хранилище ERC20.
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @dev Инициализация метаданных.
    function __ERC20_init(string memory name_, string memory symbol_, uint8 decimals_) internal {
        require(bytes(_name).length == 0, "ALREADY_INITIALIZED");
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];

        // Оптимизация: бесконечный allowance не уменьшаем.
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "INSUFFICIENT_ALLOWANCE");
            _approve(from, msg.sender, currentAllowance - amount);
        }

        _transfer(from, to, amount);
        return true;
    }

    /// @dev Внутренняя установка allowance.
    function _approve(address owner_, address spender, uint256 amount) internal virtual {
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    /// @dev Внутренний перевод.
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ZERO_TO");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "INSUFFICIENT_BALANCE");

        unchecked {
            _balances[from] = fromBalance - amount;
        }

        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    /// @dev Внутренний mint.
    function _mint(address to, uint256 amount) internal virtual {
        require(to != address(0), "ZERO_TO");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @dev Внутренний burn.
    function _burn(address from, uint256 amount) internal virtual {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "INSUFFICIENT_BALANCE");

        unchecked {
            _balances[from] = fromBalance - amount;
        }

        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}
