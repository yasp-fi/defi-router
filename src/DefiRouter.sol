// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./base/PeripheryRouter.sol";
import "./utils/Multicall.sol";

contract DefiRouter is PeripheryRouter, Multicall {
  constructor(ImmutableState memory state) PeripheryRouter(state) { }
  receive() external payable { }
}
