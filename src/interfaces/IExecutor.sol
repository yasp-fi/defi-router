// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

interface IExecutor {
  function router() external view returns (address);
  function initialize() external;
  function run(bytes32[] calldata commands, bytes[] memory stack) external payable;
}
