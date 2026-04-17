// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @dev СТАТУС: БАНДЛ / базовая заготовка.
/// @dev Это относится к тому, что на соревнованиях, вероятно, дадут или дадут очень похожим по смыслу.

/// @dev Бандл/заготовка базовой инициализации для UUPS-style контрактов.
/// @dev По смыслу соответствует тому типу init-механики, о которой говорили эксперты.

/// @title Одноразовая инициализация
abstract contract Init {
    /// @dev Признак, что инициализация уже выполнена.
    bool private _initialized;

    /// @dev Признак, что инициализация выполняется прямо сейчас.
    bool private _initializing;

    /// @notice Разрешает выполнить функцию только один раз.
    modifier initializer() {
        require(!_initialized || _initializing, "ALREADY_INITIALIZED");
        bool isTopLevel = !_initializing;

        if (isTopLevel) { _initializing = true; _initialized = true; }

        _;

        if (isTopLevel) _initializing = false;
    }
}
