// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Init} from "../utils/Init.sol";

contract Ownable is Init {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function __Ownable_init(address initializeOwner) internal {
        require(initializeOwner != address(0));
        owner = initializeOwner;
    }
    function ownershipTransfer(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}
