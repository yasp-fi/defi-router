// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import { IAllowanceTransfer } from "permit2/interfaces/IAllowanceTransfer.sol";
import "forge-std/interfaces/IERC20.sol";

interface IWETH9 is IERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external;
}

struct ImmutableState {
  address permit2;
  address weth9;
}

abstract contract PeripheryImmutableState {
  IWETH9 public immutable WETH9;
  IAllowanceTransfer public immutable PERMIT2;

  constructor(ImmutableState memory state) {
    WETH9 = IWETH9(state.weth9);
    PERMIT2 = IAllowanceTransfer(state.permit2);
  }
}
