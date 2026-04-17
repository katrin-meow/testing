// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IMarket {
    function assetManage() external view returns (uint);
    function availableLiquidity() external view returns (uint);
    function onVaultDeposit(uint amount) external;
    function onVaultWithdraw(uint amount) external;
}


