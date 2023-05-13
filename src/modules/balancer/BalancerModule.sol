// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IBalancerVault.sol";
import "./IBalancerStaking.sol";
import "../../base/PeripheryImmutableState.sol";
import "forge-std/interfaces/IERC4626.sol";

abstract contract BalancerModule is PeripheryImmutableState {
  function balancerSwap() public { }

  function balancerProvideLiquidity(
    address vault,
    bytes32 poolId,
    address payable receiver,
    uint256[] calldata maxAmountsIn,
    bytes calldata userData
  ) public {
    (IERC20[] memory tokens,,) = IBalancerVault(vault).getPoolTokens(poolId);

    IBalancerVault.JoinPoolRequest memory request = IBalancerVault
      .JoinPoolRequest({
      assets: tokens,
      maxAmountsIn: maxAmountsIn,
      userData: userData,
      fromInternalBalance: true
    });
    IBalancerVault(vault).joinPool(poolId, address(this), receiver, request);
  }

  function balancerRemoveLiquidity(
    address vault,
    bytes32 poolId,
    address payable receiver,
    uint256[] calldata minAmountsOut,
    bytes calldata userData
  ) public {
    (IERC20[] memory tokens,,) = IBalancerVault(vault).getPoolTokens(poolId);

    IBalancerVault.ExitPoolRequest memory request = IBalancerVault
      .ExitPoolRequest({
      assets: tokens,
      minAmountsOut: minAmountsOut,
      userData: userData,
      toInternalBalance: address(receiver) == address(this)
    });
    IBalancerVault(vault).exitPool(poolId, address(this), receiver, request);
  }

  function balancerStake(address gaugeVault, uint256 amount, address receiver) public {
    IERC4626(gaugeVault).deposit(amount, receiver);
  }

  function balancerUnstake(address gaugeVault, uint256 amount, address receiver) public {
    IERC4626(gaugeVault).withdraw(amount, receiver, address(this));
  }

  function balancerCollectRewards() public { }
}
