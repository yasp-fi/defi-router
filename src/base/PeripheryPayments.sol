// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "solmate/utils/SafeTransferLib.sol";
import "./PeripheryImmutableState.sol";

/// @author Uniswap Foundation
abstract contract PeripheryPayments is PeripheryImmutableState {
  receive() external payable {
    require(msg.sender == WETH9, "Not WETH9");
  }

  function unwrapWETH9(uint256 amountMinimum, address recipient) public payable {
    uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
    require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

    if (balanceWETH9 > 0) {
      IWETH9(WETH9).withdraw(balanceWETH9);
      SafeTransferLib.safeTransferETH(recipient, balanceWETH9);
    }
  }

  function sweepToken(address token, uint256 amountMinimum, address recipient)
    public
    payable
  {
    uint256 balanceToken = IERC20(token).balanceOf(address(this));
    require(balanceToken >= amountMinimum, "Insufficient token");

    if (balanceToken > 0) {
      SafeTransferLib.safeTransfer(ERC20(token), recipient, balanceToken);
    }
  }

  function refundETH() external payable {
    if (address(this).balance > 0) {
      SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }
  }

  /// @param token The token to pay
  /// @param payer The entity that must pay
  /// @param recipient The entity that will receive payment
  /// @param value The amount to pay
  function pay(address token, address payer, address recipient, uint256 value) public {
    if (token == WETH9 && address(this).balance >= value) {
      // pay with WETH9
      IWETH9(WETH9).deposit{ value: value }(); // wrap only what is needed to pay
      IWETH9(WETH9).transfer(recipient, value);
    } else if (payer == address(this)) {
      // pay with tokens already in the contract (for the exact input multihop case)
      SafeTransferLib.safeTransfer(ERC20(token), recipient, value);
    } else {
      // pull payment
      SafeTransferLib.safeTransferFrom(ERC20(token), payer, recipient, value);
    }
  }
}

abstract contract IWETH9 is ERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable virtual;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external virtual;
}
