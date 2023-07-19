// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/interfaces/IERC20.sol";
import "./mocks/ERC20.m.sol";
import "forge-std/Test.sol";
import "../src/DefiRouter.sol";
import "../src/Executor.sol";
import "../src/PermitVerifier.sol";
import "../src/libs/LibHash.sol";

contract DeFiRouterTest is Test {
  using LibHash for IRouter.SignedTransaction;

  address public OWNER = address(0xdEADBEeF00000000000000000000000000000000);
  address public USDC = address(new MockERC20("USD Coin", "USDC"));

  DeFiRouter public router;
  Executor public executor;
  PermitVerifier public verifier;
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

  bytes32 public constant _PERUNLICENSED_TRANSFER_FROM_TYPEHASH = keccak256(
    "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
  );

  function delta(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a - b : b - a;
  }

  function setUp() public {
    router = new DeFiRouter(OWNER, address(0), address(0));
    executor = new Executor(address(router));
    verifier = new PermitVerifier(address(router));

    vm.startPrank(OWNER);
    router.updateExecutorImpl(address(executor));
    router.updateVerifier(address(verifier));
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
    address actorExecutor2 = router.createExecutor(actor);
    assertEq(actorExecutor, router.executorOf(actor));
    assertEq(actorExecutor, actorExecutor2);
    assertEq(actor, IExecutor(actorExecutor).owner());
  }

  function test_executor_receive(uint256 seed, uint64 ethValue)
    public
    withActor(seed, ethValue)
  {
    address actor = vm.addr(seed);
    address actorExecutor = router.createExecutor(actor);
    payable(actorExecutor).transfer(ethValue);

    router.execute(
      abi.encodePacked(
        uint8(0), actor, uint256(ethValue), uint256(0), abi.encode(0)
      )
    );

    assertEq(actor.balance, ethValue);
  }

  // function test_executor_fallback(uint256 seed, uint64 ethValue)
  //   public
  //   withActor(seed, ethValue)
  // {
  //   address actor = vm.addr(seed);
  //   address actorExecutor = router.createExecutor(actor);
  //   actorExecutor.call{ value: ethValue }(abi.encodePacked("Wake up, Neo..."));
  // }

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

    bytes memory command =
      abi.encodeWithSelector(IERC20.transfer.selector, actor, uint256(ethValue));

    bytes memory payload = abi.encodePacked(
      uint8(0), USDC, uint256(0), uint256(command.length), command
    );

    IRouter.SignedTransaction memory signedTransaction = IRouter
      .SignedTransaction({
      nonce: 1337,
      deadline: uint48(block.timestamp),
      user: actor,
      caller: forwarder,
      payload: payload
    });

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      seed,
      keccak256(
        abi.encodePacked(
          "\x19\x01", verifier.DOMAIN_SEPARATOR(), signedTransaction.hash()
        )
      )
    );

    vm.prank(forwarder);
    router.executeFor(
      1337, uint48(block.timestamp), actor, payload, abi.encodePacked(r, s, v)
    );
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

    bytes memory command =
      abi.encodeWithSelector(IERC20.transfer.selector, actor, uint256(ethValue));

    bytes memory payload = abi.encodePacked(
      uint8(0), USDC, uint256(0), uint256(command.length), command
    );

    IRouter.SignedTransaction memory signedTransaction = IRouter
      .SignedTransaction({
      nonce: 1337,
      deadline: uint48(block.timestamp),
      user: actor,
      caller: forwarder,
      payload: payload
    });

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      seed,
      keccak256(
        abi.encodePacked(
          "\x19\x01", verifier.DOMAIN_SEPARATOR(), signedTransaction.hash()
        )
      )
    );

    router.executeFor(
      1337, uint48(block.timestamp), actor, payload, abi.encodePacked(r, s, v)
    );
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

    bytes memory command =
      abi.encodeWithSelector(IERC20.transfer.selector, actor, uint256(ethValue));

    bytes memory payload = abi.encodePacked(
      uint8(0), USDC, uint256(0), uint256(command.length), command
    );

    IRouter.SignedTransaction memory signedTransaction = IRouter
      .SignedTransaction({
      nonce: 1337,
      deadline: uint48(0),
      user: actor,
      caller: forwarder,
      payload: payload
    });

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      seed,
      keccak256(
        abi.encodePacked(
          "\x19\x01", verifier.DOMAIN_SEPARATOR(), signedTransaction.hash()
        )
      )
    );

    router.executeFor(
      1337, uint48(0), actor, payload, abi.encodePacked(r, s, v)
    );
  }

  function testFail_executeFor_replayProtection(uint256 seed, uint64 ethValue)
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

    bytes memory command =
      abi.encodeWithSelector(IERC20.transfer.selector, actor, uint256(ethValue));

    bytes memory payload = abi.encodePacked(
      uint8(0), USDC, uint256(0), uint256(command.length), command
    );

    IRouter.SignedTransaction memory signedTransaction = IRouter
      .SignedTransaction({
      nonce: 1337,
      deadline: uint48(block.timestamp),
      user: actor,
      caller: forwarder,
      payload: payload
    });

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      seed,
      keccak256(
        abi.encodePacked(
          "\x19\x01", verifier.DOMAIN_SEPARATOR(), signedTransaction.hash()
        )
      )
    );

    router.executeFor(
      1337, uint48(block.timestamp), actor, payload, abi.encodePacked(r, s, v)
    );

    vm.startPrank(forwarder);
    router.executeFor(
      1337, uint48(block.timestamp), actor, payload, abi.encodePacked(r, s, v)
    );
    router.executeFor(
      1337, uint48(block.timestamp), actor, payload, abi.encodePacked(r, s, v)
    );
    vm.stopPrank();
  }

  function testFail_executeFor_invalidMetadataNonce(
    uint256 seed,
    uint64 ethValue
  ) public {
    vm.assume(
      seed
        <
        115792089237316195423570985008687907852837564279074904382605163141518161494337
    );
    vm.assume(seed > 0);
    address actor = vm.addr(seed);
    address executor_ = router.createExecutor(actor);
    deal(USDC, executor_, ethValue);

    bytes memory command =
      abi.encodeWithSelector(IERC20.transfer.selector, actor, uint256(ethValue));

    bytes memory payload = abi.encodePacked(
      uint8(0), USDC, uint256(0), uint256(command.length), command
    );

    IRouter.SignedTransaction memory signedTransaction = IRouter
      .SignedTransaction({
      nonce: 1337,
      deadline: uint48(block.timestamp),
      user: actor,
      caller: forwarder,
      payload: payload
    });

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      seed,
      keccak256(
        abi.encodePacked(
          "\x19\x01", verifier.DOMAIN_SEPARATOR(), signedTransaction.hash()
        )
      )
    );

    vm.startPrank(forwarder);
    router.executeFor(
      7331, uint48(block.timestamp), actor, payload, abi.encodePacked(r, s, v)
    );
    vm.stopPrank();
  }

  function test_executeFor_zeroNonce(uint256 seed, uint64 ethValue) public {
    vm.assume(
      seed
        <
        115792089237316195423570985008687907852837564279074904382605163141518161494337
    );
    vm.assume(seed > 0);
    vm.assume(ethValue > 10e18);
    address actor = vm.addr(seed);
    address executor_ = router.createExecutor(actor);
    deal(USDC, executor_, ethValue);

    bytes memory command = abi.encodeWithSelector(
      IERC20.transfer.selector, actor, uint256(ethValue / 3 - 1)
    );

    bytes memory payload = abi.encodePacked(
      uint8(0), USDC, uint256(0), uint256(command.length), command
    );

    IRouter.SignedTransaction memory signedTransaction = IRouter
      .SignedTransaction({
      nonce: 0,
      deadline: uint48(block.timestamp),
      user: actor,
      caller: forwarder,
      payload: payload
    });

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      seed,
      keccak256(
        abi.encodePacked(
          "\x19\x01", verifier.DOMAIN_SEPARATOR(), signedTransaction.hash()
        )
      )
    );

    vm.startPrank(forwarder);
    router.executeFor(
      0, uint48(block.timestamp), actor, payload, abi.encodePacked(r, s, v)
    );
    router.executeFor(
      0, uint48(block.timestamp), actor, payload, abi.encodePacked(r, s, v)
    );
    router.executeFor(
      0, uint48(block.timestamp), actor, payload, abi.encodePacked(r, s, v)
    );
    vm.stopPrank();
  }

  function testFail_executor_run(uint256 seed, uint64 ethValue)
    public
    withActor(seed, ethValue)
  {
    address actor = vm.addr(seed);
    address executor_ = router.createExecutor(actor);
    deal(USDC, executor_, ethValue);

    bytes memory command = abi.encodeWithSelector(
      IERC20.transfer.selector, actor, uint256(ethValue / 3 - 1)
    );

    bytes memory payload = abi.encodePacked(
      uint8(0), USDC, uint256(0), uint256(command.length), command
    );

    IExecutor(executor_).executePayload(payload);
  }
}
