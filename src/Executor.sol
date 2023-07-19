// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/IExecutor.sol";

contract Executor is IExecutor {
  address public immutable router;
  address internal _owner;

  event Initialize(address indexed owner);

  mapping(address => mapping(bytes32 => bool)) expectedCallbacks;

  modifier onlyCallback() {
    address callbackAddr = msg.sender;
    bytes32 dataHash = keccak256(msg.data);
    require(expectedCallbacks[callbackAddr][dataHash], "Unexpected callback");
    _;
    expectedCallbacks[callbackAddr][dataHash] = false;
  }

  constructor(address router_) {
    router = router_;
  }

  receive() external payable { }

  fallback() external payable onlyCallback {
    _executeBatch(msg.data);
  }

  function initialize(address owner_) external {
    require(_owner == address(0), "Executor was already initialized");

    _owner = owner_;

    emit Initialize(owner_);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  function setCallback(address callbackAddr, bytes32 dataHash) public {
    require(
      msg.sender == address(this), "This method can only be called via call"
    );
    expectedCallbacks[callbackAddr][dataHash] = true;
  }

  function executePayload(bytes memory payload) external payable {
    require(msg.sender == router, "Only router");
    _executeBatch(payload);
  }

  function _executeBatch(bytes memory payload) internal {
    assembly {
      let length := mload(payload)
      let i := 0x20
      for {
        // Pre block is not used in "while mode"
      } lt(i, length) {
        // Post block is not used in "while mode"
      } {
        // First byte of the data is the operation.
        // We shift by 248 bits (256 - 8 [operation byte]) it right since mload will always load 32 bytes (a word).
        // This will also zero out unused data.
        let operation := shr(0xf8, mload(add(payload, i)))
        // We offset the load address by 1 byte (operation byte)
        // We shift it right by 96 bits (256 - 160 [20 address bytes]) to right-align the data and zero out unused data.
        let to := shr(0x60, mload(add(payload, add(i, 0x01))))
        // We offset the load address by 21 byte (operation byte + 20 address bytes)
        let value := mload(add(payload, add(i, 0x15)))
        // We offset the load address by 53 byte (operation byte + 20 address bytes + 32 value bytes)
        let dataLength := mload(add(payload, add(i, 0x35)))
        let data := add(payload, add(i, 0x55))
        let success := 0
        switch operation
        case 0 { success := call(gas(), to, value, data, dataLength, 0, 0) }
        case 1 { success := delegatecall(gas(), to, data, dataLength, 0, 0) }
        if eq(success, 0) {
          let errorLength := returndatasize()
          returndatacopy(0, 0, errorLength)
          revert(0, errorLength)
        }
        // Next entry starts at 85 byte + data length
        i := add(i, add(0x55, dataLength))
      }
    }
  }
}
