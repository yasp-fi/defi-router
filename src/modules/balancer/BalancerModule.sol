// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IBalancerVault.sol";
import "./IBalancerStaking.sol";
import "../../base/PeripheryImmutableState.sol";
import "../../utils/Constants.sol";
import "forge-std/interfaces/IERC4626.sol";

abstract contract BalancerModule is PeripheryImmutableState {
  function balancerSwap() public { }

  function balancerProvideLiquidity(
    address vault,
    bytes32 poolId,
    address payable receiver,
    uint256[] memory maxAmountsIn,
    bytes memory userData
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

  function balancerProvideLiquidity(
    address vault,
    bytes32 poolId,
    address token,
    address payable receiver,
    uint256 amountIn,
    uint256 minBptAmountOut
  ) public {
    (IERC20[] memory tokens,,) = IBalancerVault(vault).getPoolTokens(poolId);

    ///@dev maybe there is a better way to find tokenIndex in balancer pool...
    uint256 tokenIndex = 0;
    for (; address(tokens[tokenIndex]) != token; tokenIndex++)
    { }

    uint256[] memory maxAmountsIn = new uint256[](tokens.length);
    maxAmountsIn[tokenIndex] = amountIn == Constants.MAX_BALANCE
      ? IERC20(token).balanceOf(address(this))
      : amountIn;

    ///@notice https://docs.balancer.fi/reference/joins-and-exits/pool-joins.html#userdata
    /// [TOKEN_IN_FOR_EXACT_BPT_OUT, bptAmountOut, enterTokenIndex]
    bytes memory userData = abi.encode(2, minBptAmountOut, tokenIndex);

    balancerProvideLiquidity(vault, poolId, receiver, maxAmountsIn, userData);
  }

  function balancerRemoveLiquidity(
    address vault,
    bytes32 poolId,
    address payable receiver,
    uint256[] memory minAmountsOut,
    bytes memory userData
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

  function balancerRemoveLiquidity(
    address vault,
    bytes32 poolId,
    address token,
    address payable receiver,
    uint256 minAmountOut,
    uint256 bptAmounIn
  ) public {
    (IERC20[] memory tokens,,) = IBalancerVault(vault).getPoolTokens(poolId);
    (address pool,) = IBalancerVault(vault).getPool(poolId);

    ///@dev maybe there is a better way to find tokenIndex in balancer pool...
    uint256 tokenIndex = 0;
    for (; address(tokens[tokenIndex]) != token; tokenIndex++)
    { }

    uint256[] memory minAmountsOut = new uint256[](tokens.length);
    minAmountsOut[tokenIndex] = minAmountOut;

    bptAmounIn = bptAmounIn == Constants.MAX_BALANCE
      ? IERC20(pool).balanceOf(address(this))
      : bptAmounIn;

    ///@notice https://docs.balancer.fi/reference/joins-and-exits/pool-exits.html#userdata
    /// [EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptAmountIn, exitTokenIndex]
    bytes memory userData = abi.encode(0, bptAmounIn, tokenIndex);

    balancerRemoveLiquidity(vault, poolId, receiver, minAmountsOut, userData);
  }

  function balancerStake(address gaugeVault, uint256 amount, address receiver)
    public
  {
    IERC4626(gaugeVault).deposit(amount, receiver);
  }

  function balancerUnstake(address gaugeVault, uint256 amount, address receiver)
    public
  {
    IERC4626(gaugeVault).withdraw(amount, receiver, address(this));
  }

  function balancerCollectRewards() public { }
}
