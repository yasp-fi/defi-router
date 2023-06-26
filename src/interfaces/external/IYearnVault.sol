// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IYearnPartnerTracker {
  function token() external view returns (address);

  function deposit(address vault, address partnerId, uint256 amount) external returns (uint256);
}

interface IYearnRegistry {
  function latestVault(address token) external view returns (address);
}

interface IYearnStakingRegistry {
  function stakingPool(address vault) external view returns (address);
}

interface IYearnVault {
  function token() external view returns (address);
  function pricePerShare() external view returns (uint256);
  function decimals() external view returns (uint256);

  function withdraw(uint256 _shares) external returns (uint256);
  function withdraw(uint256 _shares, address recipient) external returns (uint256);
}