// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {ERC20Upgradeable} from "./ERC20Upgradeable.sol";

contract USDC is ERC20Upgradeable {
    constructor(address initialHolder, uint initialSupply) {
        __ERC20_init("USD Coin", "USDC", 6);
        _mint(initialHolder, initialSupply);
    }
}
