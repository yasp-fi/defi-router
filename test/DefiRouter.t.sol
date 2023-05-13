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
    ImmutableState memory state =
      ImmutableState({ permit2: PERMIT2, weth9: WETH });

    router = new DefiRouter(state);
  }

  function test_multicallAny(address user, uint256 amountIn) public {
    vm.assume(user != address(0));
    amountIn = bound(amountIn, 1e6, 1e10);

    deal(USDC, user, amountIn);

    address AAVE_POOL = address(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    vm.prank(user);
    IERC20(USDC).approve(address(router), type(uint256).max);

    IMulticall.Instruction[] memory bundle = new IMulticall.Instruction[](4);
    bundle[0] = IMulticall.Instruction({
      executable: address(router),
      data: abi.encodeWithSignature(
        "pay(address,address,address,uint256)",
        USDC,
        user,
        address(router),
        amountIn
        )
    });

    bundle[1] = IMulticall.Instruction({
      executable: address(router),
      data: abi.encodeWithSignature(
        "approveERC20(address,address,uint256)", USDC, AAVE_POOL, Constants.MAX_BALANCE
        )
    });

    bundle[2] = IMulticall.Instruction({
      executable: AAVE_POOL,
      data: abi.encodeWithSignature(
        "supply(address,uint256,address,uint16)",
        USDC,
        amountIn,
        address(router),
        uint16(0)
        )
    });

    bundle[3] = IMulticall.Instruction({
      executable: AAVE_POOL,
      data: abi.encodeWithSignature(
        "withdraw(address,uint256,address)", USDC, amountIn, user
        )
    });

    router.multicall(bundle);
  }
}
