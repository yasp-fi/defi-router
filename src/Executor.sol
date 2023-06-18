pragma solidity ^0.8.13;

import "./interfaces/IExecutor.sol";
import "./utils/LibOps.sol";
import "./utils/LibConfig.sol";
import "./utils/LibCalldata.sol";
import "./utils/Address.sol";

contract Executor is IExecutor {
  using LibConfig for bytes32;
  using LibCalldata for bytes;
  using Address for address;

  address public immutable router;
  address private _caller;
  address private _owner;

  event CallBegin(address indexed target, bytes4 indexed selector, bytes payload);
  event CallEnd(address indexed target, bytes4 indexed selector, bytes result);

  modifier checkCaller() {
    address expectedCaller = _caller;
    require(expectedCaller == msg.sender, "Invalid caller");
    if (expectedCaller != router) {
      _caller = router;
    }
    _;
  }

  constructor() {
    router = msg.sender;
  }

  function initialize() external {
    require(_caller == address(0), "Executor is already Initialized");
    _caller = router;
  }

  function execOperations(LibOps.Operation[] calldata operations) external payable checkCaller {
    bytes32[256] memory refArray;
    uint256 refIndex;

    for (uint256 i = 0; i < operations.length; i++) {
      address target = operations[i].target;
      bytes32 config = operations[i].config;
      uint256 value = operations[i].value;
      bytes memory payload = operations[i].payload;

      if (config.isDynamic()) payload.adjust(config, refArray, refIndex);

      bytes4 selector = payload.getSelector();

      emit CallBegin(target, selector, payload);
      bytes memory result = target.functionCallWithValue(payload, value);
      emit CallEnd(target, selector, result);

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
}
