pragma solidity ^0.8.13;

library Constants {
  uint256 internal constant FEE_BIPS_BASE = 10_000;
  /// Aliases
  /// @dev Used for identifying cases when this contract's balance of a token is to be used as an input
  /// This value is equivalent to 1<<255, i.e. a singular 1 in the most significant bit.
  uint256 internal constant MAX_BALANCE =
    0x8000000000000000000000000000000000000000000000000000000000000000;

  /// @dev Used as a flag for identifying the transfer of ETH instead of a token
  address internal constant ETH =
    address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
}
