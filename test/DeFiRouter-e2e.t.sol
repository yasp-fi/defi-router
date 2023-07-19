// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.17;

// import "forge-std/interfaces/IERC20.sol";
// import "forge-std/Test.sol";
// import "../src/DefiRouter.sol";
// import "../src/Executor.sol";
// import "../src/PermitVerifier.sol";
// import "../src/utils/Planner.sol";
// import "../src/libs/PayloadHash.sol";

// import "../src/interfaces/external/IAavePool.sol";
// import "../src/interfaces/external/IStargateRouter.sol";
// import "../src/interfaces/external/IStargateStaking.sol";
// import "../src/interfaces/external/IStakingRewards.sol";

// interface IWETH9 {
//   function deposit() external payable;
//   function withdraw(uint256) external;
// }

// interface ISwapRouter {
//   struct ExactInputParams {
//     bytes path;
//     address recipient;
//     uint256 deadline;
//     uint256 amountIn;
//     uint256 amountOutMinimum;
//   }

//   function exactInput(ExactInputParams memory params)
//     external
//     returns (uint256 amountOut);
// }

// ///@dev Fork E2E Tests, uses Arbitrum fork
// contract DeFiRouterE2ETest is Test {
//   using PayloadHash for IRouter.Payload;

//   address public OWNER = address(0xdEADBEeF00000000000000000000000000000000);

//   address public WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
//   address public SGETH = address(0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0);
//   address public STG = address(0x6694340fc020c5E6B96567843da2df01b2CE1eb6);
//   address public USDC = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
//   address public USDCE = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
//   address public DAI = address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
//   address public CURVE2CRV = address(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

//   address public PERUNLICENSED2 =
//     address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
//   address public AAVE_POOL = address(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
//   address public STARGATE_USDC_POOL =
//     address(0x892785f33CdeE22A30AEF750F285E18c18040c3e);
//   address public STARGATE_FACTORY =
//     address(0x55bDb4164D28FBaF0898e0eF14a589ac09Ac9970);
//   address public STARGATE_ROUTER =
//     address(0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614);
//   address public STARGATE_STAKING =
//     address(0xeA8DfEE1898a7e0a59f7527F076106d7e44c2176);
//   address public YEARN_PARTNER_TRACKER =
//     address(0x0e5b46E4b2a05fd53F5a4cD974eb98a9a613bcb7);
//   address public YEARN_REGISTRY =
//     address(0x3199437193625DCcD6F9C9e98BDf93582200Eb1f);
//   address public SWAP_ROUTER =
//     address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

//   Planner public planner;
//   Planner public subPlanner;

//   DeFiRouter public router;
//   Executor public executor;
//   PermitVerifier public verifier;
//   address public forwarder = address(0xdadada);

//   modifier withActor(uint256 seed, uint64 ethValue) {
//     vm.assume(
//       seed
//         <
//         115792089237316195423570985008687907852837564279074904382605163141518161494337
//     );
//     vm.assume(seed > 0);
//     vm.assume(ethValue > 1e8);
//     address actor = vm.addr(seed);

//     vm.deal(actor, uint256(ethValue));
//     vm.label(actor, "Actor");
//     vm.startPrank(actor);
//     _;
//     vm.stopPrank();
//   }

//   bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH =
//     keccak256("TokenPermissions(address token,uint256 amount)");

//   bytes32 public constant _PERUNLICENSED_TRANSFER_FROM_TYPEHASH = keccak256(
//     "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
//   );

//   function delta(uint256 a, uint256 b) internal pure returns (uint256) {
//     return a > b ? a - b : b - a;
//   }

//   function setUp() public {
//     planner = new Planner();
//     subPlanner = new Planner();

//     router = new DeFiRouter(OWNER, address(0), address(0));
//     executor = new Executor(address(router));
//     verifier = new PermitVerifier(address(router));

//     vm.startPrank(OWNER);
//     router.updateExecutorImpl(address(executor));
//     router.updateVerifier(address(verifier));
//     vm.stopPrank();

//     vm.label(address(router), "DeFiRouter");
//     vm.label(address(executor), "ExecutorImpl");
//   }

//   function test_weth(uint256 seed, uint64 ethValue)
//     public
//     withActor(seed, ethValue)
//   {
//     address actor = vm.addr(seed);
//     address executor_ = router.createExecutor(actor);

//     planner.callWithValue(WETH, IWETH9.deposit.selector);
//     planner.withRawArg(abi.encode(ethValue), false);

//     planner.regularCall(WETH, IWETH9.withdraw.selector);
//     planner.withRawArg(abi.encode(ethValue), false);

//     planner.callWithValue(actor, bytes4(0));
//     planner.withRawArg(abi.encode(ethValue), false);

//     (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();
//     router.execute{ value: uint256(ethValue) }(_commands, _state);

//     assertEq(actor.balance, ethValue);
//     assertEq(address(router).balance, 0);
//     assertEq(executor_.balance, 0);
//     assertEq(IERC20(WETH).balanceOf(executor_), 0);
//   }

//   function test_token(uint256 seed, uint64 ethValue)
//     public
//     withActor(seed, ethValue)
//   {
//     address actor = vm.addr(seed);
//     address executor_ = router.createExecutor(actor);
//     deal(STG, executor_, ethValue, true);
//     deal(USDC, actor, ethValue, true);

//     IERC20(USDC).approve(executor_, ethValue);

//     planner.regularCall(USDC, IERC20.transferFrom.selector);
//     planner.withRawArg(abi.encode(actor), false);
//     planner.withRawArg(abi.encode(executor_), false);
//     planner.withRawArg(abi.encode(ethValue), false);

//     planner.regularCall(STG, IERC20.transfer.selector);
//     planner.withRawArg(abi.encode(actor), false);
//     planner.withRawArg(abi.encode(ethValue), false);

//     (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();
//     router.execute{ value: 0 }(_commands, _state);

//     assertEq(IERC20(STG).balanceOf(executor_), 0);
//     assertEq(IERC20(USDC).balanceOf(executor_), ethValue);
//     assertEq(IERC20(USDC).balanceOf(actor), 0);
//     assertEq(IERC20(STG).balanceOf(actor), ethValue);
//   }

//   function test_aave(uint256 seed, uint64 ethValue)
//     public
//     withActor(seed, ethValue)
//   {
//     address actor = vm.addr(seed);
//     address executor_ = router.createExecutor(actor);
//     deal(WETH, executor_, ethValue, true);

//     planner.regularCall(WETH, IERC20.approve.selector);
//     planner.withRawArg(abi.encode(AAVE_POOL), false);
//     planner.withRawArg(abi.encode(ethValue), false);

//     planner.regularCall(AAVE_POOL, IAavePool.supply.selector);
//     planner.withRawArg(abi.encode(WETH), false);
//     planner.withRawArg(abi.encode(ethValue), false);
//     planner.withRawArg(abi.encode(executor_), false);
//     planner.withRawArg(abi.encode(0), false);

//     planner.regularCall(AAVE_POOL, IAavePool.withdraw.selector);
//     planner.withRawArg(abi.encode(WETH), false);
//     planner.withRawArg(abi.encode(ethValue), false);
//     planner.withRawArg(abi.encode(actor), false);

//     (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();
//     router.execute{ value: ethValue }(_commands, _state);
//   }

//   function test_stargate(uint256 seed, uint64 ethValue)
//     public
//     withActor(seed, ethValue)
//   {
//     address actor = vm.addr(seed);
//     address executor_ = router.createExecutor(actor);
//     deal(USDCE, executor_, ethValue, true);

//     planner.regularCall(USDCE, IERC20.approve.selector);
//     planner.withRawArg(abi.encode(STARGATE_ROUTER), false);
//     planner.withRawArg(abi.encode(ethValue), false);

//     planner.regularCall(STARGATE_ROUTER, IStargateRouter.addLiquidity.selector);
//     planner.withRawArg(abi.encode(1), false);
//     planner.withRawArg(abi.encode(ethValue), false);
//     planner.withRawArg(abi.encode(executor_), false);

//     planner.regularCall(STARGATE_USDC_POOL, IERC20.approve.selector);
//     planner.withRawArg(abi.encode(STARGATE_STAKING), false);
//     planner.withRawArg(abi.encode(ethValue), false);

//     planner.staticCall(STARGATE_USDC_POOL, IERC20.balanceOf.selector);
//     planner.withRawArg(abi.encode(executor_), false);

//     bytes1 stateIndex = planner.saveOutput();

//     planner.regularCall(STARGATE_STAKING, IStargateStaking.deposit.selector);
//     planner.withRawArg(abi.encode(0), false);
//     planner.withArg(stateIndex);

//     planner.regularCall(STARGATE_STAKING, IStargateStaking.withdraw.selector);
//     planner.withRawArg(abi.encode(0), false);
//     planner.withArg(stateIndex);

//     planner.regularCall(
//       STARGATE_ROUTER, IStargateRouter.instantRedeemLocal.selector
//     );
//     planner.withRawArg(abi.encode(1), false);
//     planner.withArg(stateIndex);
//     planner.withRawArg(abi.encode(actor), false);

//     (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();
//     router.execute{ value: ethValue }(_commands, _state);
//   }

//   function test_uniswap(uint256 seed, uint64 ethValue)
//     public
//     withActor(seed, ethValue)
//   {
//     address actor = vm.addr(seed);
//     address executor_ = router.createExecutor(actor);
//     deal(USDCE, executor_, ethValue, true);

//     planner.regularCall(USDCE, IERC20.approve.selector);
//     planner.withRawArg(abi.encode(SWAP_ROUTER), false);
//     planner.withRawArg(abi.encode(ethValue), false);

//     // Executes the swap.
//     planner.regularCall(SWAP_ROUTER, ISwapRouter.exactInput.selector);
//     planner.withRawArg(
//       abi.encode(
//         abi.encodePacked(USDCE, uint24(100), DAI),
//         executor_,
//         block.timestamp + 200,
//         ethValue,
//         0
//       ),
//       true
//     );

//     (bytes32[] memory _commands, bytes[] memory _state) = planner.encode();
//     router.execute{ value: 0 }(_commands, _state);
//   }
// }
