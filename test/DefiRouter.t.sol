// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DefiRouter.sol";

contract DefiRouterTest is Test {
  address public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public PERMIT2 = address(0x0);
  address public USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address public ADMIN = address(0xdeadbeef);

  string MAINNET_RPC_URL = "https://cloudflare-eth.com";
  uint256 mainnetFork;

  DefiRouter public router;

  function setUp() public {
    mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);

    ImmutableState memory state = ImmutableState({
      permit2: PERMIT2,
      weth9: WETH,
      v3Factory: address(0),
      poolInitCodeHash: bytes32(0)
    });

    router = new DefiRouter(state);
  }

  function test_aaveDeposit(address user, uint256 amountIn) public {
    vm.assume(user != address(0));
    amountIn = bound(amountIn, 1e18, 1e27);

    deal(USDC, user, amountIn);

    address POOL = address(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

    // Transaction 1
    vm.prank(user);
    IERC20(USDC).approve(address(router), amountIn);

    bytes[] memory data = new bytes[](2);

    data[0] = abi.encodeWithSelector(
      router.pay.selector, USDC, user, address(router), amountIn
    );

    data[1] = abi.encodeWithSelector(
      router.aaveProvideLiquidity.selector, POOL, USDC, amountIn
    );

    // Transaction 2
    router.multicall(data);
  }

  function test_aaveWithdraw(address user, uint256 amountIn) public {
    vm.assume(user != address(0));
    amountIn = bound(amountIn, 1e18, 1e27);

    deal(USDC, user, amountIn);

    address POOL = address(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

    // Transaction 1
    vm.prank(user);
    IERC20(USDC).approve(address(router), amountIn);

    bytes[] memory data = new bytes[](2);

    data[0] = abi.encodeWithSelector(
      router.pay.selector, USDC, user, address(router), amountIn
    );

    data[1] = abi.encodeWithSelector(
      router.aaveRemoveLiquidity.selector, POOL, USDC, amountIn
    );

    // Transaction 2
    router.multicall(data);
  }
}
