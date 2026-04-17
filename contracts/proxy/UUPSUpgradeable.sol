// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @dev СТАТУС: БАНДЛ / базовая заготовка логики апгрейда.
/// @dev По словам экспертов именно UUPS-схема ожидается на соревнованиях.

/// @dev Бандл/заготовка UUPS logic.
/// @dev Это core-логика upgradeable implementation, которую нужно понимать на уровне идеи.

/// @title Минимальная реализация UUPS
/// @notice Обновление implementation выполняется через implementation-контракт
abstract contract UUPSUpgradeable {
    /// @dev Слот implementation по EIP-1967.
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC;

    /// @dev Адрес текущей implementation-логики, зафиксированный в bytecode.
    address private immutable __self = address(this);

    /// @dev Разрешает вызов только через proxy на активной implementation.
    modifier onlyProxy() {
        require(address(this) != __self, "NOT_DELEGATECALL");
        require(_getImplementation() == __self, "INACTIVE_PROXY");
        _;
    }

    /// @dev Разрешает вызов только напрямую на implementation.
    modifier notDelegated() {
        require(address(this) == __self, "ONLY_IMPLEMENTATION");
        _;
    }

    /// @notice UUID UUPS-слота по EIP-1822.
    function proxiableUUID() external view notDelegated returns (bytes32) {
        return IMPLEMENTATION_SLOT;
    }

    /// @notice Обновить implementation.
    function upgradeTo(address newImplementation) external onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /// @notice Обновить implementation и сразу вызвать migration-хук.
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCall(newImplementation, data, true);
    }

    /// @dev Переопределяется наследником, обычно с модификатором onlyOwner.
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /// @dev Чтение implementation из EIP-1967-слота.
    function _getImplementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /// @dev Запись implementation и опциональный delegatecall в новую логику.
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        require(newImplementation != address(0), "ZERO_IMPL");
        _setImplementation(newImplementation);

        if (forceCall || data.length > 0) {
            (bool ok, bytes memory err) = newImplementation.delegatecall(data);
            require(ok, string(err));
        }
    }

    /// @dev Запись implementation в EIP-1967-слот.
    function _setImplementation(address newImplementation) private {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }
}
