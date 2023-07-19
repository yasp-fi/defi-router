// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/interfaces/IERC20.sol";

contract InchSwapper {
  address public immutable oneInchRouter;

  address public constant NATIVE_TOKEN_ADDRESS =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  constructor(address oneInchRouter_) {
    oneInchRouter = oneInchRouter_;
  }

  function getBalance(address token) public view returns (uint256 balance) {
    if (token == NATIVE_TOKEN_ADDRESS) {
      balance = address(this).balance;
    } else {
      balance = IERC20(token).balanceOf(address(this));
    }
  }

  function swap(
    uint256 amountIn,
    uint256 minAmountOut,
    IERC20 srcToken,
    IERC20 dstToken,
    bytes calldata data
  ) external payable returns (uint256 returnAmount) {
    uint256 dstTokenBalanceBefore = getBalance(address(dstToken));

    if (address(srcToken) == NATIVE_TOKEN_ADDRESS) {
      /// ERC20->X SWAP
      srcToken.approve(oneInchRouter, amountIn);
      _swap(0, data);
      srcToken.approve(oneInchRouter, 0);
    } else {
      /// ETH->ERC20 SWAP
      _swap(amountIn, data);
    }

     uint256 dstTokenBalanceAfter =getBalance(address(dstToken));

    require(dstTokenBalanceAfter >= dstTokenBalanceBefore, "Math underflow");
    returnAmount = dstTokenBalanceAfter - dstTokenBalanceBefore;
    require(returnAmount >= minAmountOut, "Invalid output token amount");
  }

  function _swap(uint256 msgValue, bytes calldata data)
    internal
    returns (uint256 returnAmount)
  {
    (bool success, bytes memory returnData) =
      oneInchRouter.call{ value: msgValue }(data);

    if (success) {
      returnAmount = abi.decode(returnData, (uint256));
    } else {
      require(returnData.length >= 68, "Error: 1inch Swap has failed");
      assembly {
        returnData := add(returnData, 0x04)
      }
      revert(abi.decode(returnData, (string)));
    }
  }
}
