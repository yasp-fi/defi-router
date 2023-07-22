// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IRouter {
  struct SignedTransaction {
    /// 32 bytes
    uint48 nonce;
    uint48 deadline;
    address user;
    /// 32 bytes
    uint96 gasPrice;
    address gasToken;
    /// 32 bytes
    address caller;
    /// n bytes
    bytes payload;
  }

  function executorImpl() external view returns (address);

  function executorOf(address owner) external view returns (address executor);
  function execute(bytes calldata payload) external payable;

  function executeFor(
    IRouter.SignedTransaction memory signedTransaction,
    bytes calldata signature
  ) external payable;
}
