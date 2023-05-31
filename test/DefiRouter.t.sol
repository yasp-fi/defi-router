// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DefiRouter.sol";
import "../src/modules/permit2/Permit2Module.sol";
import "../src/modules/aaveV3/AaveV3Module.sol";
import "../src/modules/stargate/StargateModule.sol";
import "../src/modules/curve/CurveModule.sol";

///@dev Fork E2E Tests, uses Arbitrum fork
contract DefiRouterTest is Test {
  address public OWNER = address(0xdEADBEeF00000000000000000000000000000000);

  address public WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public SGETH = address(0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0);
  address public USDC = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

  address public PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
  address public AAVE_POOL = address(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
  address public STARGATE_FACTORY = address(0x55bDb4164D28FBaF0898e0eF14a589ac09Ac9970);
  address public STARGATE_ROUTER = address(0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614);
  address public STARGATE_STAKING = address(0xeA8DfEE1898a7e0a59f7527F076106d7e44c2176);
  // address public CURVE_TRIPOOL = address(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
  // address public CURVE_TRIPOOL_GAUGE = address(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

  Registry public registry;
  DefiRouter public router;

  Permit2Module public permit2Module;
  AaveV3Module public aaveModule;
  StargateModule public stargateModule;
  CurveModule public curveModule;

  modifier withActor(address actor, uint64 ethValue) {
    vm.assume(ethValue > 1e8);
    vm.assume(actor != address(0));

    vm.deal(actor, uint256(ethValue));
    vm.startPrank(actor);
    _;
    vm.stopPrank();
  }

  bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

  bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
    "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
  );

  function getPermitTransferSignature(
    ISignatureTransfer.PermitTransferFrom memory permit,
    address spender,
    uint256 privateKey,
    bytes32 domainSeparator
  ) internal pure returns (bytes memory sig) {
    bytes32 tokenPermissions = keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permit.permitted));
    bytes32 msgHash = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        keccak256(abi.encode(_PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissions, spender, permit.nonce, permit.deadline))
      )
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
    return bytes.concat(r, s, bytes1(v));
  }

  function setUp() public {
    registry = new Registry(OWNER);
    router = new DefiRouter(address(registry));

    permit2Module = new Permit2Module(PERMIT2, WETH);
    aaveModule = new AaveV3Module(AAVE_POOL, WETH);
    stargateModule = new StargateModule(STARGATE_FACTORY, STARGATE_ROUTER, STARGATE_STAKING, SGETH);
    curveModule = new CurveModule(WETH);

    vm.startPrank(OWNER);
    registry.registerModule(address(permit2Module), bytes1(0x01));
    registry.registerModule(address(aaveModule), bytes1(0x01));
    registry.registerModule(address(stargateModule), bytes1(0x01));
    registry.registerModule(address(curveModule), bytes1(0x01));
    vm.stopPrank();
  }

  function test_buildConfig() public {
    uint8[] memory locs = new uint8[](1);
    locs[0] = 1;
    uint8[] memory refs = new uint8[](1);
    refs[0] = 0;
    assertEq(
      LibConfig.buildDynamic(0, locs, refs), bytes32(0x0100000000000000000200ffffffffffffffffffffffffffffffffffffffffff)
    );
    assertEq(LibConfig.buildStatic(5), bytes32(0x0005000000000000000000000000000000000000000000000000000000000000));
  }

  function test_base(address user, uint64 ethValue) public withActor(user, ethValue) {
    address[] memory modules = new address[](3);
    modules[0] = address(aaveModule);
    modules[1] = address(aaveModule);
    modules[2] = address(aaveModule);
    bytes32[] memory configs = new bytes32[](3);
    configs[0] = bytes32(0x0001000000000000000000000000000000000000000000000000000000000000);
    configs[1] = bytes32(0x0100000000000000000400ffffffffffffffffffffffffffffffffffffffffff);
    configs[2] = bytes32(0x0100000000000000000100ffffffffffffffffffffffffffffffffffffffffff);
    bytes[] memory payloads = new bytes[](3);
    payloads[0] = abi.encodeWithSelector(ModuleBase.wrapETH.selector, uint256(ethValue));
    payloads[1] = abi.encodeWithSelector(ModuleBase.pay.selector, WETH, OWNER, Constants.BIPS_BASE / 4);
    payloads[2] = abi.encodeWithSelector(ModuleBase.unwrapWETH9.selector, Constants.BIPS_BASE / 2);

    router.execute{ value: uint256(ethValue) }(modules, configs, payloads);
  }

  function test_permit2(uint64 privateKey, uint64 ethValue) public {
    vm.assume(privateKey > 1e8);
    address actor = vm.addr(privateKey);

    vm.assume(ethValue > 1e8);
    deal(WETH, actor, ethValue);

    IPermit2.SignatureTransferDetails memory details =
      ISignatureTransfer.SignatureTransferDetails({ to: address(router), requestedAmount: uint256(ethValue) });

    IPermit2.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
      permitted: ISignatureTransfer.TokenPermissions({ token: WETH, amount: uint256(ethValue) }),
      deadline: block.timestamp + 100,
      nonce: 0
    });

    bytes memory sig =
      getPermitTransferSignature(permit, address(router), privateKey, IPermit2(PERMIT2).DOMAIN_SEPARATOR());

    address[] memory modules = new address[](2);
    modules[0] = address(permit2Module);
    modules[1] = address(permit2Module);
    bytes32[] memory configs = new bytes32[](2);
    configs[0] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    configs[1] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    bytes[] memory payloads = new bytes[](2);
    payloads[0] = abi.encodeWithSelector(Permit2Module.permitTransfer.selector, permit, details, sig);
    payloads[1] = abi.encodeWithSelector(ModuleBase.unwrapWETH9.selector, uint256(ethValue));

    vm.startPrank(actor);
    IERC20(WETH).approve(PERMIT2, type(uint256).max);
    router.execute{ value: 0 }(modules, configs, payloads);
    vm.stopPrank();
  }

  function test_aave(address user, uint64 ethValue) public withActor(user, ethValue) {
    address[] memory modules = new address[](3);
    modules[0] = address(aaveModule);
    modules[1] = address(aaveModule);
    modules[2] = address(aaveModule);
    bytes32[] memory configs = new bytes32[](3);
    configs[0] = bytes32(0x0001000000000000000000000000000000000000000000000000000000000000);
    configs[1] = bytes32(0x0101000000000000000200ffffffffffffffffffffffffffffffffffffffffff);
    configs[2] = bytes32(0x0100000000000000000201ffffffffffffffffffffffffffffffffffffffffff);
    bytes[] memory payloads = new bytes[](3);
    payloads[0] = abi.encodeWithSelector(ModuleBase.wrapETH.selector, uint256(ethValue));
    payloads[1] = abi.encodeWithSelector(AaveV3Module.supply.selector, WETH, Constants.BIPS_BASE / 2);
    payloads[2] = abi.encodeWithSelector(AaveV3Module.withdraw.selector, WETH, Constants.BIPS_BASE / 2);

    router.execute{ value: uint256(ethValue) }(modules, configs, payloads);
  }

  function test_stargate(address user, uint64 ethValue) public withActor(user, ethValue) {
    address[] memory modules = new address[](2);
    modules[0] = address(stargateModule);
    modules[1] = address(stargateModule);
    bytes32[] memory configs = new bytes32[](2);
    configs[0] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    configs[1] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    bytes[] memory payloads = new bytes[](2);
    payloads[0] = abi.encodeWithSelector(StargateModule.addLiquidity.selector, Constants.NATIVE_TOKEN, ethValue);
    payloads[1] = abi.encodeWithSelector(StargateModule.removeLiquidity.selector, Constants.NATIVE_TOKEN, ethValue);

    router.execute{ value: uint256(ethValue) }(modules, configs, payloads);
  }

  // function test_curve(address user, uint256 ethValue) public withActor(user, ethValue) { }
}
