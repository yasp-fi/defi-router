// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./LibConfig.sol";
import "./LibCalldata.sol";
import "./Constants.sol";

abstract contract Executor {
  using LibConfig for bytes32;
  using LibCalldata for bytes;

  event ExecBegin(address indexed target, bytes4 indexed selector, bytes payload);
  event ExecEnd(address indexed target, bytes4 indexed selector, bytes result);

  function validateTarget(address target) internal virtual view returns (bool);

  function execute(address[] memory targets, bytes32[] memory configs, bytes[] memory payloads) internal {
    require(targets.length == configs.length, "Targets and configs length is inconsistent");
    require(targets.length == payloads.length, "Targets and payloads length is inconsistent");

    bytes32[256] memory refArray;
    uint256 refIndex;
    uint256 pc;

    for (uint256 i = 0; i < targets.length; i++) {
      address target = targets[i];
      bytes32 config = configs[i];
      bytes memory payload = payloads[i];

      require(validateTarget(target), "Target is not valid");

      // Check if the payload contains dynamic parameter
      if (config.isDynamic()) payload.adjust(config, refArray, refIndex);

      bytes4 selector = payload.getSelector();

      emit ExecBegin(target, selector, payload);
      bytes memory result = payload.exec(target, pc++);
      emit ExecEnd(target, selector, result);

      if (config.isReferenced()) {
        // If so, parse the output and place it into local stack
        uint256 size = config.getReturnSize();
        uint256 newIndex = updateReferences(refArray, result, refIndex);
        require(newIndex == refIndex + size, "Return size and parsed return size not matched");
        refIndex = newIndex;
      }
    }
  }

  function updateReferences(bytes32[256] memory refArray, bytes memory ret, uint256 index)
    internal
    pure
    returns (uint256 newIndex)
  {
    uint256 len = ret.length;
    // The return value should be multiple of 32-bytes to be parsed.
    require(len % 32 == 0, "illegal length for _parse");
    // Estimate the tail after the process.
    newIndex = index + len / 32;
    require(newIndex <= 256, "stack overflow");
    assembly {
      let offset := shl(5, index)
      // Store the data into localStack
      for { let i := 0 } lt(i, len) { i := add(i, 0x20) } {
        mstore(add(refArray, add(i, offset)), mload(add(add(ret, i), 0x20)))
      }
    }
  }
}
