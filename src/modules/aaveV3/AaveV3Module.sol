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

  function getAToken(address token) internal view returns (address aTokenAddress) {
    IPool.ReserveData memory data = AAVE.getReserveData(token);
    return data.aTokenAddress;
  }

  function positionOf(address user, address token) public view returns (uint256 amount, uint256 amountDeposited) {
    address poolToken = token == Constants.NATIVE_TOKEN ? address(WETH9) : token;
    amount = balanceOf(poolToken, user);
    amountDeposited = balanceOf(getAToken(poolToken), user);
  }

  function deposit(address token, uint256 amount) public payable returns (uint256 suppliedAmount) {
    if (token == Constants.NATIVE_TOKEN) {
      amount = wrapETH(amount);
      token = address(WETH9);
    }
    amount = balanceOf(token, amount);

    IERC20(token).approve(address(AAVE), amount);
    AAVE.supply(token, amount, address(this), REFFERAL_CODE);

    suppliedAmount = amount;

    _sweepToken(getAToken(token));
  }

  function withdraw(address token, uint256 amount) public payable returns (uint256 withdrawAmount) {
    if (token == Constants.NATIVE_TOKEN) {
      token = address(WETH9);
    }
    amount = balanceOf(getAToken(token), amount);

    withdrawAmount = AAVE.withdraw(token, amount, address(this));

    if (token == Constants.NATIVE_TOKEN) {
      withdrawAmount = unwrapWETH9(amount);
    }

    _sweepToken(token);
  }
}
