// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

interface IRouter {
  struct Payload {
    uint48 nonce;
    uint48 deadline;
    bytes32[] commands;
    bytes[] stack;
  }

  function executorImpl() external view returns (address);
  function executorOf(address owner) external view returns (address executor);
  function execute(bytes32[] memory commands, bytes[] memory stack) external payable  returns(bytes[] memory);
  function executeFor(address user, Payload memory payload, bytes calldata signature) external payable returns(bytes[] memory);
}
