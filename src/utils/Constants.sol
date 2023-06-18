pragma solidity ^0.8.13;

library Constants {
  uint256 constant MAX_BPS = 10000;

  uint256 constant IDX_VARIABLE_LENGTH = 0x80;
  uint256 constant IDX_VALUE_MASK = 0x7f;
  uint256 constant IDX_END_OF_ARGS = 0xff;
  uint256 constant IDX_USE_STATE = 0xfe;

  uint256 constant FLAG_CT_DELEGATECALL = 0x00;
  uint256 constant FLAG_CT_CALL = 0x01;
  uint256 constant FLAG_CT_STATICCALL = 0x02;
  uint256 constant FLAG_CT_VALUECALL = 0x03;
  uint256 constant FLAG_CT_MASK = 0x03;
  uint256 constant FLAG_EXTENDED_COMMAND = 0x80;
  uint256 constant FLAG_TUPLE_RETURN = 0x40;

  uint256 constant SHORT_COMMAND_FILL = 0x000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
}
