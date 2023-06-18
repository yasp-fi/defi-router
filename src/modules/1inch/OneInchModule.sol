// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../../utils/Constants.sol";
import "../ModuleBase.sol";

contract OneInchModule is ModuleBase {
  address public immutable swapRouter;

  constructor(address swapRouter_, address weth) ModuleBase(weth) {
    swapRouter = swapRouter_;
  }

  function swap(uint256 amountIn, address srcToken, address dstToken, bytes calldata data)
    external
    payable
    returns (uint256 returnAmount)
  {
    if (srcToken == Constants.NATIVE_TOKEN) {
      amountIn = wrapETH(amountIn);
      srcToken = address(WETH9);
    }

    uint256 dstTokenBalanceBefore = balanceOf(address(dstToken));

    IERC20(srcToken).approve(swapRouter, amountIn);
    returnAmount = oneInchSwap(data);
    IERC20(srcToken).approve(swapRouter, 0);

    uint256 dstTokenBalanceAfter = balanceOf(address(dstToken));
    uint256 balanceDiff = dstTokenBalanceAfter - dstTokenBalanceBefore;
    require(balanceDiff == returnAmount, "Invalid output token amount");

    _sweepToken(dstToken);
  }

  function oneInchSwap(bytes calldata data) internal returns (uint256 returnAmount) {
    (bool success, bytes memory returnData) = swapRouter.call{ value: 0 }(data);

    if (success) {
      returnAmount = abi.decode(returnData, (uint256));
    } else {
      require(returnData.length >= 68, "1inch swap has failed silently");
      assembly {
        returnData := add(returnData, 0x04)
      }
      revert(abi.decode(returnData, (string)));
    }
  }
}
