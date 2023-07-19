// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IRouter {
  struct SignedTransaction {
    address user;
    uint48 nonce;
    address caller;
    uint48 deadline;
    bytes payload;
  }

  function executorImpl() external view returns (address);

  function executorOf(address owner) external view returns (address executor);
  function execute(bytes calldata payload) external payable;
  function executeFor(
    uint48 nonce,
    uint48 deadline,
    address user,
    bytes calldata payload,
    bytes calldata signature
  ) external payable;
}
