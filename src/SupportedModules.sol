// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./modules/aavev3/AaveV3Module.sol";
import "./modules/balancer/BalancerModule.sol";
import "./modules/compound/CompoundModule.sol";
import "./modules/curve/CurveModule.sol";
import "./modules/stargate/StargateModule.sol";

abstract contract SupportedModules is
    AaveV3Module,
    BalancerModule,
    CompoundModule,
    CurveModule,
    StargateModule
{}
