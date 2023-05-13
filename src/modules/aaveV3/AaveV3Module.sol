// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "./IPool.sol";
import "../../utils/Constants.sol";

abstract contract AaveV3Module {
  uint16 constant REFFERAL_CODE = 0;

  function aaveAToken(address lendingPool, address asset)
    public
    view
    returns (address aTokenAddress)
  {
    IPool.ReserveData memory data = IPool(lendingPool).getReserveData(asset);
    return data.aTokenAddress;
  }

  function aaveProvideLiquidity(
    address lendingPool,
    address asset,
    address receiver,
    uint256 value
  ) public {
    value = value == Constants.MAX_BALANCE
      ? IERC20(asset).balanceOf(address(this))
      : value;

    IPool(lendingPool).supply(asset, value, receiver, REFFERAL_CODE);
  }

  function aaveRemoveLiquidity(
    address lendingPool,
    address asset,
    address receiver,
    uint256 value
  ) public {
    address aToken = aaveAToken(lendingPool, asset);
    
    value = value == Constants.MAX_BALANCE
      ? IERC20(aToken).balanceOf(address(this))
      : value;

    IPool(lendingPool).withdraw(asset, value, receiver);
  }

  function aaveCollectRewards() public { }
}
