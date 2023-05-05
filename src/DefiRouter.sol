// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./base/PeripheryPaymentsWithFee.sol";
import "./utils/Multicall.sol";
import "./utils/SelfPermit.sol";
import "./SupportedModules.sol";

contract DefiRouter is SupportedModules, PeripheryPaymentsWithFee, Multicall, SelfPermit {
    constructor(address _WETH9) PeripheryImmutableState(_WETH9) {}
}
