// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC4626.sol";
import "./IStargateRouter.sol";
import "./IStargateLPStaking.sol";

abstract contract StargateModule {
  function stargateProvideLiquidity(
    address router,
    uint256 poolId,
    uint256 assets
  ) public {
    IStargateRouter(router).addLiquidity(poolId, assets, address(this));
  }

  function stargateRemoveLiquidity(
    address router,
    uint16 poolId,
    uint256 assets
  ) public {
    IStargateRouter(router).instantRedeemLocal(poolId, assets, address(this));
  }
}
