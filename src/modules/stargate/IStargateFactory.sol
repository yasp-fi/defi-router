// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./IStargatePool.sol";

interface IStargateFactory {
    function getPool(uint256) external view returns (IStargatePool);
    function allPools(uint256) external view returns (address);
    function allPoolsLength() external view returns (uint256);
}
