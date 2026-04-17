// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {ERC20Upgradeable} from "./ERC20Upgradeable.sol";

contract USDT is ERC20Upgradeable {
    constructor(address initialHolder, uint initialSupply) {
        __ERC20_init("Tether USD", "USDT", 6);
        _mint(initialHolder, initialSupply);
    }
}
