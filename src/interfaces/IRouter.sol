// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

interface IRouter {
  function executorImpl() external view returns (address);
  function executorOf(address owner) external view returns (address executor);
  function execute(bytes32[] calldata commands, bytes[] memory stack) external payable;
}
