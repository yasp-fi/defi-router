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
  address v2Factory;
  address v3Factory;
  bytes32 pairInitCodeHash;
  bytes32 poolInitCodeHash;
}

abstract contract PeripheryImmutableState {
  IWETH9 public immutable WETH9;
  IAllowanceTransfer public immutable PERMIT2;

  /// @dev The address of UniswapV2Factory
  address internal immutable UNISWAP_V2_FACTORY;
  /// @dev The UniswapV2Pair initcodehash
  bytes32 internal immutable UNISWAP_V2_PAIR_INIT_CODE_HASH;
  /// @dev The address of UniswapV3Factory
  address public immutable UNISWAP_V3_FACTORY;
  /// @dev The UniswapV3Pool initcodehash
  bytes32 public immutable UNISWAP_V3_POOL_INIT_CODE_HASH;


  constructor(ImmutableState memory state) {
    WETH9 = IWETH9(state.weth9);
    PERMIT2 = IAllowanceTransfer(state.permit2);
    UNISWAP_V2_FACTORY = state.v2Factory;
    UNISWAP_V2_PAIR_INIT_CODE_HASH = state.pairInitCodeHash;
    UNISWAP_V3_FACTORY = state.v3Factory;
    UNISWAP_V3_POOL_INIT_CODE_HASH = state.poolInitCodeHash;
  }
}
