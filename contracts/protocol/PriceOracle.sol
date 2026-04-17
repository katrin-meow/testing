// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @dev СТАТУС: ПИШУ САМА.

import {Ownable} from "../acess/Ownable.sol";
import {UUPSUpgradeable} from "../proxy/UUPSUpgradeable.sol";

contract PriceOracle is Ownable, UUPSUpgradeable {
    uint256 public constant PRICE_SCALE = 1e18;
    mapping(address => uint256) public prices;

    function initialize(address owner_) external initializer { __Ownable_init(owner_); }

    function setPrice(address token, uint256 price) external onlyOwner {
        require(token != address(0), "ZERO_TOKEN");
        require(price > 0, "ZERO_PRICE");
        prices[token] = price;
    }

    function getPrice(address token) external view returns (uint256) {
        uint256 price = prices[token];
        require(price > 0, "PRICE_NOT_SET");
        return price;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
