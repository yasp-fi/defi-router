// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "../utils/LibOps.sol";

interface IRouter {
  function executorImpl() external view returns (address);
  function executorOf(address owner) external view returns (address executor);
  function execute(LibOps.OperationBatch calldata batch) external payable;
}
