// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @dev СТАТУС: БАНДЛ / базовая заготовка прокси.
/// @dev По словам экспертов именно UUPS-схема ожидается на соревнованиях.

/// @dev Бандл/заготовка UUPS proxy.
/// @dev Это прокси-обертка, через которую создаются отдельные экземпляры Vault/Market при одном implementation.

/// @title Минимальный ERC1967-proxy для UUPS
/// @notice Используется вместе с implementation-контрактами, наследующими UUPSUpgradeable
contract UUPSProxy {
    /// @dev Слот implementation по EIP-1967.
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC;

    /// @notice Конструктор прокси.
    /// @param implementation_ Адрес implementation-логики.
    /// @param initData Данные вызова initialize, которые выполняются через delegatecall.
    constructor(address implementation_, bytes memory initData) {
        require(implementation_ != address(0), "ZERO_IMPL");

        _setImplementation(implementation_);

        if (initData.length > 0) {
            (bool ok, bytes memory err) = implementation_.delegatecall(initData);
            require(ok, string(err));
        }
    }

    /// @notice Текущий implementation.
    function implementation() external view returns (address) {
        return _implementation();
    }

    fallback() external payable {
        _delegate(_implementation());
    }

    receive() external payable {
        _delegate(_implementation());
    }

    function _delegate(address impl) private {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _implementation() private view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    function _setImplementation(address impl) private {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, impl)
        }
    }
}
