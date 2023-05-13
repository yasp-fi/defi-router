// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DefiRouter.sol";

contract DefiRouterTest is Test {
  address public WETH = address(0x4200000000000000000000000000000000000006);
  address public PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
  address public USDC = address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607);

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
    router.aaveProvideLiquidity(POOL, USDC, address(router), Constants.MAX_BALANCE);
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

  // function test_balancer(address user, uint256 amountIn) public {
  //   vm.assume(user != address(0));
  //   amountIn = bound(amountIn, 1e18, 1e27);

  //   deal(USDC, user, amountIn);

  //   vm.prank(user);

  //   IERC20(USDC).approve(address(router), type(uint256).max);
  //   router.pay(USDC, address(router), amountIn);
  // }
}
