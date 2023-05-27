// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./utils/LibConfig.sol";
import "./utils/LibCalldata.sol";
import "./utils/Constants.sol";

abstract contract Executor {
  using LibConfig for bytes32;
  using LibCalldata for bytes;

  event ExecBegin(address indexed target, bytes4 indexed selector, bytes payload);
  event ExecEnd(address indexed target, bytes4 indexed selector, bytes result);

  modifier isNotHalted() {
    require(!_isHalted(), "Halted");
    _;
  }

  fallback() external payable isNotHalted {
    require(_validateCallback(msg.sender), "Invalid callback");
    address target = _getCallackTarget(msg.sender);
    bytes memory result = msg.data.exec(target, type(uint256).max);

    uint256 size = result.length;
    assembly {
      let loc := add(result, 0x20)
      return(loc, size)
    }
  }

  receive() external payable {
    require(msg.sender.code.length > 0, "Not allowed from EOA");
  }

  function _execute(address[] memory targets, bytes32[] memory configs, bytes[] memory payloads) internal {
    require(targets.length == configs.length, "Targets and configs length is inconsistent");
    require(targets.length == payloads.length, "Targets and payloads length is inconsistent");

    bytes32[256] memory refArray;
    uint256 refIndex;
    uint256 pc;

    for (uint256 i = 0; i < targets.length; i++) {
      address target = targets[i];
      bytes32 config = configs[i];
      bytes memory payload = payloads[i];

      require(_validateTarget(target), "Target is not valid");

      if (config.isDynamic()) payload.adjust(config, refArray, refIndex);

      bytes4 selector = payload.getSelector();

      emit ExecBegin(target, selector, payload);
      bytes memory result = payload.exec(target, pc++);
      emit ExecEnd(target, selector, result);

      if (config.isReferenced()) {
        uint256 size = config.getReturnSize();
        uint256 newIndex = _updateReferences(refArray, result, refIndex);
        require(newIndex == refIndex + size, "Return size and parsed return size not matched");
        refIndex = newIndex;
      }
    }
  }

  function _updateReferences(bytes32[256] memory refArray, bytes memory ret, uint256 index)
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
      // Store the data into refArray
      for { let i := 0 } lt(i, len) { i := add(i, 0x20) } {
        mstore(add(refArray, add(i, offset)), mload(add(add(ret, i), 0x20)))
      }
    }
  }

  function _isHalted() internal view virtual returns (bool);
  function _validateTarget(address target) internal view virtual returns (bool);
  function _validateCallback(address callback) internal view virtual returns (bool);
  function _getCallackTarget(address callback) internal view virtual returns (address);
}
