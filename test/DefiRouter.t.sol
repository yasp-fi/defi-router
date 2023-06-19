// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "permit2/interfaces/ISignatureTransfer.sol";
import "forge-std/interfaces/IERC20.sol";
import "forge-std/Test.sol";
import "../src/DefiRouter.sol";
import "../src/Executor.sol";
import "../src/utils/Planner.sol";

import "../src/interfaces/external/IAavePool.sol";
import "../src/interfaces/external/IStargateRouter.sol";
import "../src/interfaces/external/IStargateStaking.sol";
import "../src/interfaces/external/IStakingRewards.sol";

interface IWETH9 {
  function deposit() external payable;
  function withdraw(uint256) external;
}

///@dev Fork E2E Tests, uses Arbitrum fork
contract DefiRouterTest is Test {
  address public OWNER = address(0xdEADBEeF00000000000000000000000000000000);

  address public WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public SGETH = address(0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0);
  address public STG = address(0x6694340fc020c5E6B96567843da2df01b2CE1eb6);
  address public USDC = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
  address public CURVE2CRV = address(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

  address public PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
  address public AAVE_POOL = address(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
  address public STARGATE_USDC_POOL = address(0x892785f33CdeE22A30AEF750F285E18c18040c3e);
  address public STARGATE_FACTORY = address(0x55bDb4164D28FBaF0898e0eF14a589ac09Ac9970);
  address public STARGATE_ROUTER = address(0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614);
  address public STARGATE_STAKING = address(0xeA8DfEE1898a7e0a59f7527F076106d7e44c2176);
  address public YEARN_PARTNER_TRACKER = address(0x0e5b46E4b2a05fd53F5a4cD974eb98a9a613bcb7);
  address public YEARN_REGISTRY = address(0x3199437193625DCcD6F9C9e98BDf93582200Eb1f);

  Planner public planner;
  DeFiRouter public router;
  Executor public executor;

  modifier withActor(address actor, uint64 ethValue) {
    vm.assume(ethValue > 1e8);
    vm.assume(actor != address(0));

    vm.deal(actor, uint256(ethValue));
    vm.label(actor, "Actor");
    vm.startPrank(actor);
    _;
    vm.stopPrank();
  }

  bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

  bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
    "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
  );

  function delta(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a - b : b - a;
  }

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
    planner = new Planner();
    router = new DeFiRouter(OWNER, address(0));
    executor = new Executor(address(router));
    vm.startPrank(OWNER);
    router.updateExecutorImpl(address(executor));
    vm.stopPrank();

    vm.label(address(router), "DeFiRouter");
    vm.label(address(executor), "Executor");
  }

  function test_getExecutorAddress(address user1, address user2) public {
    assertEq(user1 == user2, router.getExecutorAddress(user1) == router.getExecutorAddress(user2));
  }

  function test_createExecutor(address user, uint64 ethValue) public withActor(user, ethValue) {
    address userExecutor = router.createExecutor(user);
    assertEq(userExecutor, router.getExecutorAddress(user));
  }

  function test_weth(address user, uint64 ethValue) public withActor(user, ethValue) {
    address executor_ = router.createExecutor(user);

    planner.callWithValue(WETH, IWETH9.deposit.selector);
    planner.withRawArg(abi.encode(ethValue), false);

    planner.regularCall(WETH, IWETH9.withdraw.selector);
    planner.withRawArg(abi.encode(ethValue), false);

    planner.callWithValue(user, bytes4(0));
    planner.withRawArg(abi.encode(ethValue), false);

    (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();
    router.execute{ value: uint256(ethValue) }(_commands, _state);

    assertEq(user.balance, ethValue);
    assertEq(address(router).balance, 0);
    assertEq(executor_.balance, 0);
    assertEq(IERC20(WETH).balanceOf(executor_), 0);
  }

  function test_token(address user, uint64 ethValue) public withActor(user, ethValue) {
    address executor_ = router.createExecutor(user);
    deal(STG, executor_, ethValue);
    deal(USDC, user, ethValue);

    IERC20(USDC).approve(executor_, ethValue);

    planner.regularCall(USDC, IERC20.transferFrom.selector);
    planner.withRawArg(abi.encode(user), false);
    planner.withRawArg(abi.encode(executor_), false);
    planner.withRawArg(abi.encode(ethValue), false);

    planner.regularCall(STG, IERC20.transfer.selector);
    planner.withRawArg(abi.encode(user), false);
    planner.withRawArg(abi.encode(ethValue), false);

    (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();
    router.execute{ value: 0 }(_commands, _state);

    assertEq(IERC20(STG).balanceOf(executor_), 0);
    assertEq(IERC20(USDC).balanceOf(executor_), ethValue);
    assertEq(IERC20(USDC).balanceOf(user), 0);
    assertEq(IERC20(STG).balanceOf(user), ethValue);
  }

  function test_aave(address user, uint64 ethValue) public withActor(user, ethValue) {
    address executor_ = router.createExecutor(user);
    deal(WETH, executor_, ethValue);

    planner.regularCall(WETH, IERC20.approve.selector);
    planner.withRawArg(abi.encode(AAVE_POOL), false);
    planner.withRawArg(abi.encode(ethValue), false);

    planner.regularCall(AAVE_POOL, IAavePool.supply.selector);
    planner.withRawArg(abi.encode(WETH), false);
    planner.withRawArg(abi.encode(ethValue), false);
    planner.withRawArg(abi.encode(executor_), false);
    planner.withRawArg(abi.encode(0), false);

    planner.regularCall(AAVE_POOL, IAavePool.withdraw.selector);
    planner.withRawArg(abi.encode(WETH), false);
    planner.withRawArg(abi.encode(ethValue), false);
    planner.withRawArg(abi.encode(user), false);

    (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();
    router.execute{ value: ethValue }(_commands, _state);
  }

  function test_stargate(address user, uint64 ethValue) public withActor(user, ethValue) {
    address executor_ = router.createExecutor(user);
    deal(USDC, executor_, ethValue);

    planner.regularCall(USDC, IERC20.approve.selector);
    planner.withRawArg(abi.encode(STARGATE_ROUTER), false);
    planner.withRawArg(abi.encode(ethValue), false);

    planner.regularCall(STARGATE_ROUTER, IStargateRouter.addLiquidity.selector);
    planner.withRawArg(abi.encode(1), false);
    planner.withRawArg(abi.encode(ethValue), false);
    planner.withRawArg(abi.encode(executor_), false);

    planner.regularCall(STARGATE_USDC_POOL, IERC20.approve.selector);
    planner.withRawArg(abi.encode(STARGATE_STAKING), false);
    planner.withRawArg(abi.encode(ethValue), false);

    planner.staticCall(STARGATE_USDC_POOL, IERC20.balanceOf.selector);
    planner.withRawArg(abi.encode(executor_), false);

    bytes1 stateIndex = planner.saveOutput();

    planner.regularCall(STARGATE_STAKING, IStargateStaking.deposit.selector);
    planner.withRawArg(abi.encode(0), false);
    planner.withArg(stateIndex);

    planner.regularCall(STARGATE_STAKING, IStargateStaking.withdraw.selector);
    planner.withRawArg(abi.encode(0), false);
    planner.withArg(stateIndex);

    planner.regularCall(STARGATE_ROUTER, IStargateRouter.instantRedeemLocal.selector);
    planner.withRawArg(abi.encode(1), false);
    planner.withArg(stateIndex);
    planner.withRawArg(abi.encode(user), false);

    (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();
    router.execute{ value: ethValue }(_commands, _state);
  }

  // function test_yearn(address user, uint64 ethValue) public withActor(user, ethValue) {
  //   deal(CURVE2CRV, user, ethValue);
  //   IERC20(CURVE2CRV).approve(address(router), type(uint256).max);

  //   address[] memory modules = new address[](3);
  //   modules[0] = address(yearnModule);
  //   modules[1] = address(yearnModule);
  //   modules[2] = address(yearnModule);
  //   bytes32[] memory configs = new bytes32[](3);
  //   configs[0] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
  //   configs[1] = bytes32(0x0001000000000000000000000000000000000000000000000000000000000000);
  //   configs[2] = bytes32(0x0100000000000000000200ffffffffffffffffffffffffffffffffffffffffff);
  //   bytes[] memory payloads = new bytes[](3);
  //   payloads[0] = abi.encodeWithSelector(ModuleBase.pull.selector, CURVE2CRV, ethValue);
  //   payloads[1] = abi.encodeWithSelector(YearnModule.deposit.selector, CURVE2CRV, ethValue);
  //   payloads[2] = abi.encodeWithSelector(YearnModule.withdraw.selector, CURVE2CRV, Constants.BIPS_BASE / 2);

  //   router.execute{ value: uint256(ethValue) }(modules, configs, payloads);

  //   (uint256 amount, uint256 amountDeposited) = yearnModule.positionOf(user, CURVE2CRV);
  //   assertLe(delta(amount, ethValue / 2), 10);
  //   assertLe(delta(amountDeposited, ethValue / 2), 10);

  //   (uint256 rAmount, uint256 rAmountDeposited) = yearnModule.positionOf(address(router), CURVE2CRV);
  //   assertEq(rAmount, 0);
  //   assertEq(rAmountDeposited, 0);
  // }

  // function test_hop(address user, uint64 ethValue) public withActor(user, ethValue) { }

  // function test_symbiosis(address user, uint64 ethValue) public withActor(user, ethValue) { }
}
