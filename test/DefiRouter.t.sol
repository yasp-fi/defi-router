// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DefiRouter.sol";
import "../src/modules/permit2/Permit2Module.sol";
import "../src/modules/aaveV3/AaveV3Module.sol";

///@dev Fork E2E Tests, uses Arbitrum fork
contract DefiRouterTest is Test {
  address public OWNER = address(0xdEADBEeF00000000000000000000000000000000);

  address public WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public USDC = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

  address public PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
  address public AAVE_POOL = address(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

  Registry public registry;
  DefiRouter public router;

  Permit2Module public permit2Module;
  AaveV3Module public aaveModule;

  modifier withActor(address actor, uint256 ethValue) {
    vm.assume(10e18 > ethValue && ethValue > 10e15);
    vm.deal(actor, ethValue);
    vm.startPrank(actor);
    _;
    vm.stopPrank();
  }

  function setUp() public {
    registry = new Registry(OWNER);
    router = new DefiRouter(address(registry));

    permit2Module = new Permit2Module(PERMIT2, WETH);
    aaveModule = new AaveV3Module(AAVE_POOL, WETH);

    vm.startPrank(OWNER);
    registry.registerModule(address(permit2Module), bytes1(0x01));
    registry.registerModule(address(aaveModule), bytes1(0x01));
    vm.stopPrank();
  }

  function test_permit2() public { }

  function test_aave(address user, uint256 ethValue) public withActor(user, ethValue) {
    bytes4 wrapSelector = bytes4(keccak256("wrapETH(address,uint256)"));
    bytes4 supplySelector = bytes4(keccak256("supply(address,address,uint256)"));
    bytes4 withdrawSelector = bytes4(keccak256("withdraw(address,address,uint256)"));

    address[] memory modules = new address[](3);
    modules[0] = address(aaveModule);
    modules[1] = address(aaveModule);
    modules[2] = address(aaveModule);
    bytes32[] memory configs = new bytes32[](3);
    configs[0] = bytes32(0x0);
    configs[1] = bytes32(0x0);
    configs[2] = bytes32(0x0);
    bytes[] memory payloads = new bytes[](3);
    payloads[0] = abi.encodeWithSelector(wrapSelector, address(router), ethValue);
    payloads[1] = abi.encodeWithSelector(supplySelector, WETH, address(router), ethValue);
    payloads[2] = abi.encodeWithSelector(withdrawSelector, WETH, user, ethValue);

    router.execute{ value: ethValue }(modules, configs, payloads);
  }

  function test_curve(address user, uint256 ethValue) public withActor(user, ethValue) { }
  function test_stargate(address user, uint256 ethValue) public withActor(user, ethValue) { }
}
