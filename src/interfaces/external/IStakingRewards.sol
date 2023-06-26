// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IStakingRewards {
  function balanceOf(address owner) external view returns (uint256);
  function pendingReward(address owner) external view returns (uint256);
  function stakeFor(address recipient, uint256 amount) external;
  function withdraw(uint256 amount) external;
  function getReward() external;
}
