// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/interfaces/IERC20.sol";
import "./mocks/ERC20.m.sol";
import "forge-std/Test.sol";
import "../src/DefiRouter.sol";
import "../src/Executor.sol";
import "../src/utils/Planner.sol";

contract DefiRouterTest is Test {
  using PayloadHash for IRouter.Payload;

  address public OWNER = address(0xdEADBEeF00000000000000000000000000000000);
  address public USDC = address(new MockERC20("USD Coin", "USDC"));

  Planner public planner;
  Planner public subPlanner;

  DeFiRouter public router;
  Executor public executor;
  address public forwarder = address(0xdadada);

  modifier withActor(uint256 seed, uint64 ethValue) {
    vm.assume(
      seed
        <
        115792089237316195423570985008687907852837564279074904382605163141518161494337
    );
    vm.assume(seed > 0);
    vm.assume(ethValue > 1e8);
    address actor = vm.addr(seed);

    vm.deal(actor, uint256(ethValue));
    vm.label(actor, "Actor");
    vm.startPrank(actor);
    _;
    vm.stopPrank();
  }

  bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH =
    keccak256("TokenPermissions(address token,uint256 amount)");

  bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
    "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
  );

  function delta(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a - b : b - a;
  }

  function setUp() public {
    planner = new Planner();
    subPlanner = new Planner();
    router = new DeFiRouter(OWNER, address(0));
    executor = new Executor(address(router));
    vm.startPrank(OWNER);
    router.updateExecutorImpl(address(executor));
    router.updateForwarder(forwarder, true);
    vm.stopPrank();

    vm.label(address(router), "DeFiRouter");
    vm.label(address(executor), "ExecutorImpl");
  }

  function test_getExecutorAddress(address actor1, address actor2) public {
    assertEq(
      actor1 == actor2, router.executorOf(actor1) == router.executorOf(actor2)
    );
  }

  function test_createExecutor(uint256 seed, uint64 ethValue)
    public
    withActor(seed, ethValue)
  {
    address actor = vm.addr(seed);
    address actorExecutor = router.createExecutor(actor);
    assertEq(actorExecutor, router.executorOf(actor));
    assertEq(actor, IExecutor(actorExecutor).owner());
  }

  function test_executor_receive(uint256 seed, uint64 ethValue)
    public
    withActor(seed, ethValue)
  {
    address actor = vm.addr(seed);
    address actorExecutor = router.createExecutor(actor);
    payable(actorExecutor).transfer(ethValue);
    planner.callWithValue(actor, bytes4(0));
    planner.withRawArg(abi.encode(ethValue), false);

    (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();
    router.execute(_commands, _state);
    assertEq(actor.balance, ethValue);
  }

  function test_executor_fallback(uint256 seed, uint64 ethValue)
    public
    withActor(seed, ethValue)
  {
    address actor = vm.addr(seed);
    address actorExecutor = router.createExecutor(actor);
    actorExecutor.call{ value: ethValue }(abi.encodePacked("Wake up, Neo..."));
  }

  function test_executeFor(uint256 seed, uint64 ethValue) public {
    vm.assume(
      seed
        <
        115792089237316195423570985008687907852837564279074904382605163141518161494337
    );
    vm.assume(seed > 0);
    address actor = vm.addr(seed);
    address executor_ = router.createExecutor(actor);
    deal(USDC, executor_, ethValue);

    planner.regularCall(USDC, IERC20.transfer.selector);
    planner.withRawArg(abi.encode(actor), false);
    planner.withRawArg(abi.encode(ethValue), false);

    (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();

    IRouter.Payload memory payload = IRouter.Payload({
      nonce: 1337,
      deadline: uint48(block.timestamp),
      user: actor,
      commands: _commands,
      state: _state
    });

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      seed,
      keccak256(
        abi.encodePacked("\x19\x01", router.DOMAIN_SEPARATOR(), payload.hash())
      )
    );
    bytes32 metadata = abi.decode(
      abi.encodePacked(uint48(1337), uint48(block.timestamp), bytes20(actor)),
      (bytes32)
    );

    vm.prank(forwarder);
    router.executeFor(_commands, _state, metadata, abi.encodePacked(r, s, v));
    assertEq(IERC20(USDC).balanceOf(actor), ethValue);
  }

  function testFail_executeFor_invalidForwarder(uint256 seed, uint64 ethValue)
    public
  {
    vm.assume(
      seed
        <
        115792089237316195423570985008687907852837564279074904382605163141518161494337
    );
    vm.assume(seed > 0);
    address actor = vm.addr(seed);
    address executor_ = router.createExecutor(actor);
    deal(USDC, executor_, ethValue);

    planner.regularCall(USDC, IERC20.transfer.selector);
    planner.withRawArg(abi.encode(actor), false);
    planner.withRawArg(abi.encode(ethValue), false);

    (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();

    IRouter.Payload memory payload = IRouter.Payload({
      nonce: 1337,
      deadline: uint48(block.timestamp),
      user: actor,
      commands: _commands,
      state: _state
    });

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      seed,
      keccak256(
        abi.encodePacked("\x19\x01", router.DOMAIN_SEPARATOR(), payload.hash())
      )
    );
    bytes32 metadata = abi.decode(
      abi.encodePacked(uint48(1337), uint48(block.timestamp), bytes20(actor)),
      (bytes32)
    );

    router.executeFor(_commands, _state, metadata, abi.encodePacked(r, s, v));
    // TODO: check error emit
  }

  function testFail_executeFor_signatureExpired(uint256 seed, uint64 ethValue)
    public
  {
    vm.assume(
      seed
        <
        115792089237316195423570985008687907852837564279074904382605163141518161494337
    );
    vm.assume(seed > 0);
    address actor = vm.addr(seed);
    address executor_ = router.createExecutor(actor);
    deal(USDC, executor_, ethValue);

    planner.regularCall(USDC, IERC20.transfer.selector);
    planner.withRawArg(abi.encode(actor), false);
    planner.withRawArg(abi.encode(ethValue), false);

    (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();

    IRouter.Payload memory payload = IRouter.Payload({
      nonce: 1337,
      deadline: 0,
      user: actor,
      commands: _commands,
      state: _state
    });

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      seed,
      keccak256(
        abi.encodePacked("\x19\x01", router.DOMAIN_SEPARATOR(), payload.hash())
      )
    );
    bytes32 metadata = abi.decode(
      abi.encodePacked(uint48(1337), uint48(0), bytes20(actor)), (bytes32)
    );

    vm.prank(forwarder);
    router.executeFor(_commands, _state, metadata, abi.encodePacked(r, s, v));
    // TODO: check error emit
  }

  function testFail_executeFor_invalidNonce(uint256 seed, uint64 ethValue)
    public
  {
    vm.assume(
      seed
        <
        115792089237316195423570985008687907852837564279074904382605163141518161494337
    );
    vm.assume(seed > 0);
    address actor = vm.addr(seed);
    address executor_ = router.createExecutor(actor);
    deal(USDC, executor_, ethValue);

    planner.regularCall(USDC, IERC20.transfer.selector);
    planner.withRawArg(abi.encode(actor), false);
    planner.withRawArg(abi.encode(ethValue), false);

    (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();

    IRouter.Payload memory payload = IRouter.Payload({
      nonce: 1337,
      deadline: uint48(block.timestamp),
      user: actor,
      commands: _commands,
      state: _state
    });

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      seed,
      keccak256(
        abi.encodePacked("\x19\x01", router.DOMAIN_SEPARATOR(), payload.hash())
      )
    );
    bytes32 metadata = abi.decode(
      abi.encodePacked(uint48(1337), uint48(block.timestamp), bytes20(actor)),
      (bytes32)
    );

    vm.startPrank(forwarder);
    router.executeFor(_commands, _state, metadata, abi.encodePacked(r, s, v));
    router.executeFor(_commands, _state, metadata, abi.encodePacked(r, s, v));
    vm.stopPrank();
    // TODO: check error emit
  }

  function testFail_executor_run(uint256 seed, uint64 ethValue)
    public
    withActor(seed, ethValue)
  {
    address actor = vm.addr(seed);
    address executor_ = router.createExecutor(actor);
    deal(USDC, executor_, ethValue);

    planner.regularCall(USDC, IERC20.transfer.selector);
    planner.withRawArg(abi.encode(actor), false);
    planner.withRawArg(abi.encode(ethValue), false);

    (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();
    IExecutor(executor_).run(_commands, _state);
  }
}
