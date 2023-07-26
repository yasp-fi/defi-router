// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IExecutor {
  function router() external view returns (address);
  function initialize(address owner) external;
  function owner() external view returns (address);
  function setCallback(uint8 callbackId) external;
  function executePayload(bytes calldata payload) external payable;
  function payGas(
    address caller,
    uint256 gasUsed,
    address gasToken,
    uint256 gasPrice
  ) external returns (uint256 amountPaid);
}
