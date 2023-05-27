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

  function supply(address asset, address receiver, uint256 value) public payable {
    uint256 balance = IERC20(asset).balanceOf(address(this));
    require(balance >= value, "Error: insufficient amount of ERC20 token");

    IERC20(asset).approve(address(AAVE), value);
    AAVE.supply(asset, value, receiver, REFFERAL_CODE);
  }

  function withdraw(address asset, address receiver, uint256 value) public payable returns (uint256 withdrawAmount) {
    address aToken = getAToken(asset);

    uint256 balance = IERC20(aToken).balanceOf(address(this));
    require(balance >= value, "Error: insufficient amount of ERC20 token");

    withdrawAmount = AAVE.withdraw(asset, value, receiver);
  }
}
