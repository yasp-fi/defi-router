// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "./IPool.sol";

abstract contract AaveV3Module {
  function aave__provideLiquidity(
    address lendingPool,
    address asset,
    uint256 value
  ) public {
    IERC20(asset).approve(lendingPool, value);
    IPool(lendingPool).supply(address(asset), value, address(this), 0);
  }

  function aave__removeLiquidity(
    address lendingPool,
    address aToken,
    uint256 value
  ) public {
    IERC20(aToken).approve(lendingPool, value);
    IPool(lendingPool).withdraw(address(aToken), value, address(this));
  }

  function aave__collectRewards() public { }
}
