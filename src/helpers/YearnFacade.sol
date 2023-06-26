// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/interfaces/IERC20.sol";
import "../interfaces/external/IYearnVault.sol";
import "../interfaces/external/IStakingRewards.sol";

contract YearnFacade {
  IYearnRegistry public immutable registry;
  IYearnPartnerTracker public immutable tracker;
  address public immutable partnerAddress;
  address public immutable stakeRegistry;

  constructor(
    address tracker_,
    address registry_,
    address stakeRegistry_,
    address partner
  ) {
    tracker = IYearnPartnerTracker(tracker_);
    registry = IYearnRegistry(registry_);
    stakeRegistry = stakeRegistry_;
    partnerAddress = partner;
  }

  function getPosition(address token)
    public
    view
    returns (address lpToken, address stakingPool)
  {
    lpToken = registry.latestVault(token);
    bool haveStaking = stakeRegistry != address(0);

    stakingPool = haveStaking
      ? IYearnStakingRegistry(stakeRegistry).stakingPool(lpToken)
      : address(0);
  }

  function deposit(address token, uint256 amount)
    public
    payable
    returns (uint256 sharesAdded)
  {
    address vault = registry.latestVault(token);

    IERC20(token).approve(address(tracker), amount);

    sharesAdded =
      IYearnPartnerTracker(tracker).deposit(vault, partnerAddress, amount);

    (, address stakingPool) = getPosition(token);
    if (stakingPool != address(0)) {
      IERC20(vault).approve(stakingPool, sharesAdded);
      IStakingRewards(stakingPool).stakeFor(msg.sender, sharesAdded);
    }
  }

  function withdraw(address token, uint256 amount)
    public
    payable
    returns (uint256 assets)
  {
    address vault = registry.latestVault(token);

    try IYearnVault(vault).withdraw(amount, address(this)) returns (
      uint256 amountRemoved_
    ) {
      assets = amountRemoved_;
    } catch {
      assets = IYearnVault(vault).withdraw(amount);
    }
  }

  function convertShareToAsset(address token, uint256 amount)
    internal
    view
    returns (uint256)
  {
    IYearnVault vault = IYearnVault(registry.latestVault(token));
    return amount * vault.pricePerShare() / 10 ** vault.decimals();
  }

  function convertAssetToShare(address token, uint256 shares)
    internal
    view
    returns (uint256)
  {
    IYearnVault vault = IYearnVault(registry.latestVault(token));
    return shares * 10 ** vault.decimals() / vault.pricePerShare();
  }
}
