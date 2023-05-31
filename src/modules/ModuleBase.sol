// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import "forge-std/interfaces/IERC20.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/tokens/ERC1155.sol";
import "../utils/Constants.sol";
import "../utils/LibStack.sol";

interface IWETH9 is IERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external;
}

abstract contract ModuleBase {
  using LibStack for bytes32[];

  IWETH9 public immutable WETH9;

  bytes32[] internal stack;

  constructor(address weth) {
    WETH9 = IWETH9(weth);
  }

  function balanceOf(address token, uint256 minAmount) internal view returns (uint256) {
    uint256 balance = token == address(0) || token == Constants.NATIVE_TOKEN
      ? address(this).balance
      : IERC20(token).balanceOf(address(this));

    if (minAmount == type(uint256).max) {
      return balance;
    }

    require(balance >= minAmount, "Error: insufficient token balance");
    return minAmount;
  }

  function wrapETH(uint256 amount) public payable returns (uint256 wappedAmount) {
    require(amount <= address(this).balance, "Error: Insufficient ETH");

    if (amount > 0) {
      WETH9.deposit{ value: amount }();
    }
    wappedAmount = amount;
    _sweepToken(address(WETH9));
  }

  function unwrapWETH9(uint256 amount) public payable returns (uint256 unwrappedAmount) {
    require(amount <= WETH9.balanceOf(address(this)), "Error: Insufficient ETH");

    if (amount > 0) {
      WETH9.withdraw(amount);
    }
    unwrappedAmount = amount;
  }

  function pay(address token, address recipient, uint256 amount) public payable {
    amount = balanceOf(token, amount);
    if (token == Constants.NATIVE_TOKEN) {
      SafeTransferLib.safeTransferETH(recipient, amount);
    } else {
      SafeTransferLib.safeTransfer(ERC20(token), recipient, amount);
    }
  }

  function _sweepToken(address token) internal {
    stack.pushAddress(token);
    stack.pushSig(Constants.SWEEP_SIG);
  }
}
