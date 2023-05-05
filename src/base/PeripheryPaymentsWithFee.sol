// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "solmate/utils/SafeTransferLib.sol";
import "./PeripheryPayments.sol";

/// @author Uniswap Foundation
abstract contract PeripheryPaymentsWithFee is PeripheryPayments {
  function unwrapWETH9WithFee(
    uint256 amountMinimum,
    address recipient,
    uint256 feeBips,
    address feeRecipient
  ) public payable {
    require(feeBips > 0 && feeBips <= 100);

    uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
    require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

    if (balanceWETH9 > 0) {
      IWETH9(WETH9).withdraw(balanceWETH9);
      uint256 feeAmount = balanceWETH9 * feeBips / 10_000;
      if (feeAmount > 0) {
        SafeTransferLib.safeTransferETH(feeRecipient, feeAmount);
      }
      SafeTransferLib.safeTransferETH(recipient, balanceWETH9 - feeAmount);
    }
  }

  function sweepTokenWithFee(
    address token,
    uint256 amountMinimum,
    address recipient,
    uint256 feeBips,
    address feeRecipient
  ) public payable {
    require(feeBips > 0 && feeBips <= 100);

    uint256 balanceToken = IERC20(token).balanceOf(address(this));
    require(balanceToken >= amountMinimum, "Insufficient token");

    if (balanceToken > 0) {
      uint256 feeAmount = balanceToken * feeBips / 10_000;
      if (feeAmount > 0) {
        SafeTransferLib.safeTransfer(ERC20(token), feeRecipient, feeAmount);
      }
      SafeTransferLib.safeTransfer(ERC20(token), recipient, balanceToken - feeAmount);
    }
  }
}
