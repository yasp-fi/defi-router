// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";

interface IBalancerVault {
  function getPoolTokens(bytes32 poolId)
    external
    view
    returns (
      IERC20[] memory tokens,
      uint256[] memory balances,
      uint256 lastChangeBlock
  );

  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest memory request
  ) external payable;

  struct JoinPoolRequest {
    IERC20[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  function exitPool(
    bytes32 poolId,
    address sender,
    address payable recipient,
    ExitPoolRequest memory request
  ) external;

  struct ExitPoolRequest {
    IERC20[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }
}
