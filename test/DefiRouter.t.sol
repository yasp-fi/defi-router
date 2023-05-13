// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DefiRouter.sol";

///@dev Fork E2E Tests, uses Arbitrum fork
contract DefiRouterTest is Test {
  address public WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
  address public USDC = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

  DefiRouter public router;

  function setUp() public {
    ImmutableState memory state = ImmutableState({
      permit2: PERMIT2,
      weth9: WETH,
      v3Factory: address(0),
      poolInitCodeHash: bytes32(0)
    });

    router = new DefiRouter(state);
  }

  function test_aave(address user, uint256 amountIn) public {
    vm.assume(user != address(0));
    amountIn = bound(amountIn, 1e6, 1e10);

    deal(USDC, user, amountIn);

    address POOL = address(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    IERC20 aToken = IERC20(router.aaveAToken(POOL, USDC));

    vm.prank(user);
    IERC20(USDC).approve(address(router), type(uint256).max);
    router.pay(USDC, user, address(router), amountIn);
    router.approveERC20(USDC, POOL, Constants.MAX_BALANCE);
    router.aaveProvideLiquidity(
      POOL, USDC, address(router), Constants.MAX_BALANCE
    );
    router.approveERC20(address(aToken), POOL, Constants.MAX_BALANCE);
    router.aaveRemoveLiquidity(POOL, USDC, user, Constants.MAX_BALANCE);
  }

  // function test_compound(address user, uint256 amountIn) public {
  //   vm.assume(user != address(0));
  //   amountIn = bound(amountIn, 1e18, 1e27);

  //   deal(USDC, user, amountIn);

  //   vm.prank(user);

  //   IERC20(USDC).approve(address(router), type(uint256).max);
  //   router.pay(USDC, address(router), amountIn);
  // }

  function test_balancer(address user, uint256 amountIn) public {
    vm.assume(user != address(0));
    amountIn = bound(amountIn, 1e6, 1e10);

    deal(USDC, user, amountIn);

    address VAULT = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    bytes32 POOL = bytes32(
      0xce6195089b302633ed60f3f427d1380f6a2bfbc7000200000000000000000424
    );

    vm.prank(user);
    IERC20(USDC).approve(address(router), type(uint256).max);
    router.pay(USDC, user, address(router), amountIn);
    router.approveERC20(USDC, VAULT, Constants.MAX_BALANCE);
    router.balancerProvideLiquidity(
      VAULT, POOL, USDC, payable(address(router)), Constants.MAX_BALANCE, 0
    );
    router.balancerRemoveLiquidity(
      VAULT, POOL, USDC, payable(user), 0, Constants.MAX_BALANCE
    );
  }

  function test_curve(address user, uint256 amountIn) public {
    vm.assume(user != address(0));
    amountIn = bound(amountIn, 1e6, 1e10);

    deal(USDC, user, amountIn);

    address POOL = address(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

    vm.prank(user);
    IERC20(USDC).approve(address(router), type(uint256).max);
    router.pay(USDC, user, address(router), amountIn);
    router.approveERC20(USDC, POOL, Constants.MAX_BALANCE);
    router.curveProvideLiquidity(POOL, USDC, Constants.MAX_BALANCE);
    router.curveRemoveLiquidity(POOL, USDC, Constants.MAX_BALANCE);
  }
}
