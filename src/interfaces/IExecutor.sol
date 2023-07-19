// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IExecutor {
  function router() external view returns (address);
  function initialize(address owner) external;
  function owner() external view returns (address);
  function executePayload(bytes calldata payload) external payable;
}
