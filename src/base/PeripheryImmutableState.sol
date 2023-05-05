// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

abstract contract PeripheryImmutableState {
  address public immutable WETH9;

  constructor(address _WETH9) {
    WETH9 = _WETH9;
  }
}
