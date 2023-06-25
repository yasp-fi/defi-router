// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

interface IRouter {
  struct Payload {
    uint48 nonce;
    uint48 deadline;
    address user;
    bytes32[] commands;
    bytes[] state;
  }


  function executorImpl() external view returns (address);

  function executorOf(address owner) external view returns (address executor);

  function execute(bytes32[] memory commands, bytes[] memory state)
    external
    payable
    returns (bytes[] memory);

  function executeFor(
    bytes32[] memory commands,
    bytes[] memory state,
    bytes32 metadata,
    bytes memory signature
  ) external returns (bytes[] memory);
}
