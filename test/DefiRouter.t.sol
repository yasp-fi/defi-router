// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DefiRouter.sol";

contract DefiRouterTest is Test {
  address public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
  address public USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

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
    amountIn = bound(amountIn, 1e18, 1e27);

    deal(USDC, user, amountIn);

    address POOL = address(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

    vm.prank(user);

    IERC20(USDC).approve(address(router), type(uint256).max);
    router.payOrPermit2Transfer(USDC, user, address(router), amountIn);
    router.approveERC20(USDC, POOL, amountIn);
    router.aaveProvideLiquidity(POOL, USDC, address(router), amountIn);
    router.aaveRemoveLiquidity(POOL, USDC, user, amountIn);
  }

  // function test_compound(address user, uint256 amountIn) public {
  //   vm.assume(user != address(0));
  //   amountIn = bound(amountIn, 1e18, 1e27);

  //   deal(USDC, user, amountIn);

  //   vm.prank(user);

  //   IERC20(USDC).approve(address(router), type(uint256).max);
  //   router.pay(USDC, address(router), amountIn);
  // }

  // function test_balancer(address user, uint256 amountIn) public {
  //   vm.assume(user != address(0));
  //   amountIn = bound(amountIn, 1e18, 1e27);

  //   deal(USDC, user, amountIn);

  //   vm.prank(user);

  //   IERC20(USDC).approve(address(router), type(uint256).max);
  //   router.pay(USDC, address(router), amountIn);
  // }
}
