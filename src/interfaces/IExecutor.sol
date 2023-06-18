// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "../utils/LibOps.sol";

interface IExecutor {
  function router() external view returns (address);
  function initialize() external;
  function execOperations(LibOps.Operation[] calldata operations) external payable;
}