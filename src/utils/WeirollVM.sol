// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "./LibState.sol";

library WeirollVM {
  using LibState for bytes[];

  uint256 constant FLAG_CT_DELEGATECALL = 0x00;
  uint256 constant FLAG_CT_CALL = 0x01;
  uint256 constant FLAG_CT_STATICCALL = 0x02;
  uint256 constant FLAG_CT_VALUECALL = 0x03;
  uint256 constant FLAG_CT_MASK = 0x03;
  uint256 constant FLAG_EXTENDED_COMMAND = 0x80;
  uint256 constant FLAG_TUPLE_RETURN = 0x40;

  uint256 constant SHORT_COMMAND_FILL =
    0x000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  error ExecutionFailed(uint256 command_index, address target, string message);

  function execute(bytes32[] calldata commands, bytes[] memory state)
    internal
    returns (bytes[] memory)
  {
    bytes32 command;
    address target;
    uint256 flags;
    bytes32 indices;

    bool success;
    bytes memory outdata;

    for (uint256 i; i < commands.length; i++) {
      command = commands[i];
      flags = uint256(uint8(bytes1(command << 32)));
      target = address(uint160(uint256(command)));

      if (flags & FLAG_EXTENDED_COMMAND != 0) {
        indices = commands[i++];
      } else {
        indices = bytes32(uint256(command << 40) | SHORT_COMMAND_FILL);
      }
      if (flags & FLAG_CT_MASK == FLAG_CT_DELEGATECALL) {
        // delegate call
        (success, outdata) =
          target.delegatecall(state.buildInputs(bytes4(command), indices));
      } else if (flags & FLAG_CT_MASK == FLAG_CT_CALL) {
        // call
        (success, outdata) =
          target.call(state.buildInputs(bytes4(command), indices));
      } else if (flags & FLAG_CT_MASK == FLAG_CT_STATICCALL) {
        // static call
        (success, outdata) =
          target.staticcall(state.buildInputs(bytes4(command), indices));
      } else if (flags & FLAG_CT_MASK == FLAG_CT_VALUECALL) {
        // call with value
        uint256 calleth;
        bytes memory v = state[uint8(bytes1(indices))];
        require(v.length == 32, "_execute: value call has no value indicated.");
        assembly {
          calleth := mload(add(v, 0x20))
        }
        (success, outdata) = target.call{ value: calleth }(
          state.buildInputs(
            bytes4(command),
            bytes32(uint256(indices << 8) | LibState.IDX_END_OF_ARGS)
          )
        );
      } else {
        revert("Invalid calltype");
      }

      if (!success) {
        if (outdata.length > 0) {
          assembly {
            outdata := add(outdata, 68)
          }
        }
        revert ExecutionFailed({
          command_index: i,
          target: target,
          message: outdata.length > 0 ? string(outdata) : "Unknown"
        });
      }

      if (flags & FLAG_TUPLE_RETURN != 0) {
        state.writeTuple(bytes1(command << 88), outdata);
      } else {
        state = state.writeOutputs(bytes1(command << 88), outdata);
      }
    }
    return state;
  }
}
