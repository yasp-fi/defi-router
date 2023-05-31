// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IStargatePool {
  function poolId() external view returns (uint256);
  function token() external view returns (address);
  function totalSupply() external view returns (uint256);
  function totalLiquidity() external view returns (uint256);
  function convertRate() external view returns (uint256);
  function amountLPtoLD(uint256 _amountLP) external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function approve(address recipient, uint256 amount) external;
}