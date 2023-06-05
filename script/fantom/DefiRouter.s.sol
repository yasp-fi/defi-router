// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { IAllowanceTransfer } from "permit2/interfaces/IAllowanceTransfer.sol";
import "forge-std/interfaces/IERC20.sol";
import "../../src/DefiRouter.sol";
import "../../src/Registry.sol";
import "../../src/modules/aaveV3/AaveV3Module.sol";
import "../../src/modules/stargate/StargateModule.sol";
import "../../src/modules/yearn/YearnModule.sol";

contract DefiRouterScript is Script {
  address public REGISTRY = address(0x0);

  address public WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public SGETH = address(0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0);

  address public PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);

  address public AAVE_POOL = address(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

  address public STARGATE_FACTORY = address(0x55bDb4164D28FBaF0898e0eF14a589ac09Ac9970);
  address public STARGATE_ROUTER = address(0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614);
  address public STARGATE_STAKING = address(0xeA8DfEE1898a7e0a59f7527F076106d7e44c2176);

  address public YEARN_PARTNER_TRACKER = address(0x0e5b46E4b2a05fd53F5a4cD974eb98a9a613bcb7);
  address public YEARN_REGISTRY = address(0x3199437193625DCcD6F9C9e98BDf93582200Eb1f);

  function run() public returns (DefiRouter deployed) {
    uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONIC"), 0);
    Registry registry = Registry(REGISTRY);

    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);

    vm.startBroadcast(deployerPrivateKey);

    deployed = new DefiRouter(address(registry));

    AaveV3Module aaveModule = new AaveV3Module(AAVE_POOL, WETH);
    YearnModule yearnModule = new YearnModule(YEARN_PARTNER_TRACKER, YEARN_REGISTRY, registry.owner(), WETH);

    registry.registerModule(address(aaveModule), bytes1(0x01));
    registry.registerModule(address(yearnModule), bytes1(0x01));

    vm.stopBroadcast();
  }
}
