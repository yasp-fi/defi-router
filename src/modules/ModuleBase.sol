// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import "forge-std/interfaces/IERC20.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/tokens/ERC1155.sol";
import "../utils/Constants.sol";

interface IWETH9 is IERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external;
}

abstract contract ModuleBase {
  IWETH9 public immutable WETH9;

  constructor(address weth) {
    WETH9 = IWETH9(weth);
  }

  function wrapETH(address recipient, uint256 amount) public payable returns (uint256 wappedAmount) {
    require(amount <= address(this).balance, "Error: Insufficient ETH");

    if (amount > 0) {
      WETH9.deposit{ value: amount }();
      if (recipient != address(this)) {
        WETH9.transfer(recipient, amount);
      }
    }
    wappedAmount = amount;
  }

  function unwrapWETH9(address recipient, uint256 amountMinimum) public payable returns (uint256 unwrappedAmount) {
    uint256 value = WETH9.balanceOf(address(this));
    require(value >= amountMinimum, "Error: Insufficient ETH");
    if (value > 0) {
      WETH9.withdraw(value);
      if (recipient != address(this)) {
        SafeTransferLib.safeTransferETH(recipient, value);
      }
    }
    unwrappedAmount = value;
  }

  function sweep(address token, address recipient, uint256 amountMinimum) public payable {
    if (token == Constants.NATIVE_TOKEN) {
      uint256 balance = address(this).balance;
      require(balance >= amountMinimum, "Error: Insufficient ETH balance");

      if (balance > 0) {
        SafeTransferLib.safeTransferETH(recipient, balance);
      }
    } else {
      uint256 balance = ERC20(token).balanceOf(address(this));
      require(balance >= amountMinimum, "Error: Insufficient ERC20 balance");

      if (balance > 0) {
        SafeTransferLib.safeTransfer(ERC20(token), recipient, balance);
      }
    }
  }

  function sweepERC721(address token, address recipient, uint256 id) public payable {
    ERC721(token).safeTransferFrom(address(this), recipient, id);
  }

  function sweepERC1155(address token, address recipient, uint256 id, uint256 amountMinimum) public payable {
    uint256 balance = ERC1155(token).balanceOf(address(this), id);
    require(balance >= amountMinimum, "Error: Insufficient ERC1155 balance");
    ERC1155(token).safeTransferFrom(address(this), recipient, id, balance, bytes(""));
  }

  function payPortion(address token, address recipient, uint256 bips) public payable {
    require(bips != 0 && bips <= Constants.BIPS_BASE, "Error: invalid bips");
    if (token == Constants.NATIVE_TOKEN) {
      uint256 balance = address(this).balance;
      uint256 amount = (balance * bips) / Constants.BIPS_BASE;
      SafeTransferLib.safeTransferETH(recipient, amount);
    } else {
      uint256 balance = ERC20(token).balanceOf(address(this));
      uint256 amount = (balance * bips) / Constants.BIPS_BASE;
      SafeTransferLib.safeTransfer(ERC20(token), recipient, amount);
    }
  }

  function checkERC721Owner(address token, address owner, uint256 id) public payable {
    require(ERC721(token).ownerOf(id) == owner, "Error: invalid owner for ERC721");
  }

  function checkERC1155Balance(address token, address owner, uint256 id, uint256 minBalance) public payable {
    require(ERC1155(token).balanceOf(owner, id) >= minBalance, "Error: invalid balance for ERC1155");
  }

  function checkERC20Balance(address token, address owner, uint256 minBalance) public payable {
    require(ERC20(token).balanceOf(owner) >= minBalance, "Error: invalid balance for ERC20");
  }
}
