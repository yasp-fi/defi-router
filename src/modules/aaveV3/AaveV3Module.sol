// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "./IPool.sol";
import "../../utils/Constants.sol";
import "../ModuleBase.sol";

contract AaveV3Module is ModuleBase {
  uint16 constant REFFERAL_CODE = 0;

  IPool public immutable AAVE;

  constructor(address lendingPool, address weth) ModuleBase(weth) {
    AAVE = IPool(lendingPool);
  }

  function getAToken(address asset) internal view returns (address aTokenAddress) {
    IPool.ReserveData memory data = AAVE.getReserveData(asset);
    return data.aTokenAddress;
  }

  function supply(address asset, uint256 value) public payable returns (uint256 suppliedAmount) {
    value = balanceOf(asset, value);

    IERC20(asset).approve(address(AAVE), value);
    AAVE.supply(asset, value, address(this), REFFERAL_CODE);

    suppliedAmount = value;

    _sweepToken(getAToken(asset));
  }

  function withdraw(address asset, uint256 value) public payable returns (uint256 withdrawAmount) {
    value = balanceOf(getAToken(asset), value);

    withdrawAmount = AAVE.withdraw(asset, value, address(this));

    _sweepToken(asset);
  }
}
