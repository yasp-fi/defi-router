// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "./IPool.sol";

abstract contract AaveV3Module {
  function aaveProvideLiquidity(
    address lendingPool,
    address asset,
    uint256 value
  ) public {
    IPool(lendingPool).supply(address(asset), value, address(this), 0);
  }

  function aaveRemoveLiquidity(
    address lendingPool,
    address aToken,
    uint256 value
  ) public {
    IPool(lendingPool).withdraw(address(aToken), value, address(this));
  }

  function aaveCollectRewards() public { }
}
