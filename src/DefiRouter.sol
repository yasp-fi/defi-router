// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./base/PeripheryPermit2.sol";
import "./utils/Multicall.sol";

abstract contract SupportedModules is PeripheryPermit2, Multicall { }

contract DefiRouter is SupportedModules {
  constructor(ImmutableState memory state) PeripheryImmutableState(state) { }
  receive() external payable { }
}
