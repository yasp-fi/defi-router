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
  address public REGISTRY = address(0xf23d618cEd4F7F6fb5e094670D315f79Ca462710);

  address public WETH = address(0x4200000000000000000000000000000000000006);

  // address public PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);

  address public AAVE_POOL = address(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

  // address public SGETH = address(0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0);
  // address public STARGATE_FACTORY = address(0x55bDb4164D28FBaF0898e0eF14a589ac09Ac9970);
  // address public STARGATE_ROUTER = address(0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614);
  // address public STARGATE_STAKING = address(0xeA8DfEE1898a7e0a59f7527F076106d7e44c2176);

  address public YEARN_PARTNER_TRACKER = address(0x7E08735690028cdF3D81e7165493F1C34065AbA2);
  address public YEARN_REGISTRY = address(0x79286Dd38C9017E5423073bAc11F53357Fc5C128);

  function run() public returns (DefiRouter deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
    Registry registry = Registry(REGISTRY);

    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);

    vm.startBroadcast(deployerPrivateKey);

    deployed = new DefiRouter(address(registry));

    AaveV3Module aaveModule = new AaveV3Module(AAVE_POOL, WETH);
    YearnModule yearnModule = new YearnModule(YEARN_PARTNER_TRACKER, YEARN_REGISTRY, registry.owner(), WETH);

    registry.registerModule(address(aaveModule), bytes1(0x01));
    registry.registerModule(address(yearnModule), bytes1(0x01));
    uint256 ethValue = 10000000000000;

    address[] memory modules = new address[](3);
    modules[0] = address(yearnModule);
    modules[1] = address(aaveModule);
    modules[2] = address(yearnModule);
    bytes32[] memory configs = new bytes32[](3);
    configs[0] = bytes32(0x0001000000000000000000000000000000000000000000000000000000000000);
    configs[1] = bytes32(0x0100000000000000000200ffffffffffffffffffffffffffffffffffffffffff);
    configs[2] = bytes32(0x0100000000000000000200ffffffffffffffffffffffffffffffffffffffffff);
    bytes[] memory payloads = new bytes[](3);
    payloads[0] = abi.encodeWithSelector(ModuleBase.wrapETH.selector, ethValue);
    payloads[1] = abi.encodeWithSelector(YearnModule.deposit.selector, WETH, Constants.BIPS_BASE / 2);
    payloads[2] = abi.encodeWithSelector(AaveV3Module.deposit.selector, WETH, Constants.BIPS_BASE / 2);

    deployed.execute{ value: uint256(ethValue) }(modules, configs, payloads);

    vm.stopBroadcast();
  }
}
