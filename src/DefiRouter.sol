// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./base/PeripheryPermit2.sol";
import "./modules/aaveV3/AaveV3Module.sol";
import "./modules/compound/CompoundModule.sol";
import "./modules/curve/CurveModule.sol";
import "./modules/balancer/BalancerModule.sol";
import "./modules/uniswapV3/UniswapV3Module.sol";
import "./utils/Multicall.sol";

abstract contract SupportedModules is
  PeripheryPermit2,
  Multicall,
  UniswapV3Module,
  AaveV3Module,
  CurveModule,
  BalancerModule
{ }

contract DefiRouter is SupportedModules {
  constructor(ImmutableState memory state) PeripheryImmutableState(state) { }
  receive() external payable { }
}
