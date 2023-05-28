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

    vm.startPrank(OWNER);
    registry.registerModule(address(permit2Module), bytes1(0x01));
    registry.registerModule(address(aaveModule), bytes1(0x01));
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

  function test_base(address user, uint256 ethValue) public withActor(user, ethValue) {
    address[] memory modules = new address[](4);
    modules[0] = address(aaveModule);
    modules[1] = address(aaveModule);
    modules[2] = address(aaveModule);
    modules[3] = address(aaveModule);
    bytes32[] memory configs = new bytes32[](4);
    configs[0] = bytes32(0x0001000000000000000000000000000000000000000000000000000000000000);
    configs[1] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    configs[2] = bytes32(0x0100000000000000000200ffffffffffffffffffffffffffffffffffffffffff);
    configs[3] = bytes32(0x0100000000000000000400ffffffffffffffffffffffffffffffffffffffffff);
    bytes[] memory payloads = new bytes[](4);
    payloads[0] = abi.encodeWithSelector(ModuleBase.wrapETH.selector, address(router), ethValue);
    payloads[1] = abi.encodeWithSelector(ModuleBase.payPortion.selector, WETH, user, Constants.BIPS_BASE / 2);
    payloads[2] = abi.encodeWithSelector(ModuleBase.unwrapWETH9.selector, user, Constants.BIPS_BASE / 2);
    payloads[3] = abi.encodeWithSelector(ModuleBase.checkERC20Balance.selector, WETH, user, Constants.BIPS_BASE / 2);

    router.execute{ value: ethValue }(modules, configs, payloads);
  }

  function test_permit2(uint256 ethValue) public {
    uint256 privateKey = 0x123456789abcdef;
    address actor = vm.addr(privateKey);

    vm.assume(10e18 > ethValue && ethValue > 10e15);
    vm.deal(actor, ethValue);

    IPermit2.SignatureTransferDetails memory details =
      ISignatureTransfer.SignatureTransferDetails({ to: address(router), requestedAmount: ethValue });

    IPermit2.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
      permitted: ISignatureTransfer.TokenPermissions({ token: WETH, amount: ethValue }),
      deadline: block.timestamp + 100,
      nonce: 0
    });

    bytes memory sig =
      getPermitTransferSignature(permit, address(router), privateKey, IPermit2(PERMIT2).DOMAIN_SEPARATOR());

    address[] memory modules = new address[](4);
    modules[0] = address(permit2Module);
    modules[1] = address(permit2Module);
    modules[2] = address(permit2Module);
    modules[3] = address(permit2Module);
    bytes32[] memory configs = new bytes32[](4);
    configs[0] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    configs[1] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    configs[2] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    configs[3] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    bytes[] memory payloads = new bytes[](4);
    payloads[0] = abi.encodeWithSelector(ModuleBase.wrapETH.selector, actor, ethValue);
    payloads[1] = abi.encodeWithSelector(Permit2Module.permitTransfer.selector, permit, details, sig);
    payloads[2] = abi.encodeWithSelector(ModuleBase.sweep.selector, WETH, actor, ethValue);
    payloads[3] = abi.encodeWithSelector(ModuleBase.checkERC20Balance.selector, WETH, actor, ethValue);

    vm.startPrank(actor);
    IERC20(WETH).approve(PERMIT2, type(uint256).max);
    router.execute{ value: ethValue }(modules, configs, payloads);
    vm.stopPrank();
  }

  function test_aave(address user, uint256 ethValue) public withActor(user, ethValue) {
    address[] memory modules = new address[](4);
    modules[0] = address(aaveModule);
    modules[1] = address(aaveModule);
    modules[2] = address(aaveModule);
    modules[3] = address(aaveModule);
    bytes32[] memory configs = new bytes32[](4);
    configs[0] = bytes32(0x0001000000000000000000000000000000000000000000000000000000000000);
    configs[1] = bytes32(0x0100000000000000000400ffffffffffffffffffffffffffffffffffffffffff);
    configs[2] = bytes32(0x0100000000000000000400ffffffffffffffffffffffffffffffffffffffffff);
    configs[3] = bytes32(0x0100000000000000000400ffffffffffffffffffffffffffffffffffffffffff);
    bytes[] memory payloads = new bytes[](4);
    payloads[0] = abi.encodeWithSelector(ModuleBase.wrapETH.selector, address(router), ethValue);
    payloads[1] = abi.encodeWithSelector(AaveV3Module.supply.selector, WETH, address(router), Constants.BIPS_BASE);
    payloads[2] = abi.encodeWithSelector(AaveV3Module.withdraw.selector, WETH, user, Constants.BIPS_BASE);
    payloads[3] = abi.encodeWithSelector(ModuleBase.checkERC20Balance.selector, WETH, user, Constants.BIPS_BASE);

    router.execute{ value: ethValue }(modules, configs, payloads);
  }

  function test_stargate(address user, uint256 ethValue) public withActor(user, ethValue) { }

  function test_curve(address user, uint256 ethValue) public withActor(user, ethValue) { }
}
