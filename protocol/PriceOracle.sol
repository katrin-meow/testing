// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "../acess/Ownable.sol";
import {UUPSUpgradeable} from "../proxy/UUPSUpgradeable.sol";

contract PriceOracle is Ownable, UUPSUpgradeable {
    uint public constant PRICE_SCALE = 1e18;

    mapping(address => uint) public prices;

    function initialize(address owner_) external initializer {
        __Ownable_init(owner_);
    }

    function setPrice(address token, uint price) external onlyOwner {
        require(token != address(0));
        require(price != 0);
        prices[token] = price;
    }
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
