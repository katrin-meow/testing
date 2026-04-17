// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20Upgradeable} from "./ERC20Upgradeable.sol";

contract DAI is ERC20Upgradeable {
    constructor(address initialHolder, uint initialSupply) {
        __ERC20_init("Dai Stablecoin", "DAI", 18);
        _mint(initialHolder, initialSupply);
    }
}
