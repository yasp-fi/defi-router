// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IRouter.sol";

library PayloadHash {
  bytes32 public constant _PAYLOAD_TYPEHASH =
    keccak256("Payload(uint48 nonce,uint48 expiration,bytes32[] commands, bytes[] stack)");

  function hash(IRouter.Payload memory payload) internal pure returns (bytes32) {
    uint256 numStackItems = payload.stack.length;
    bytes32[] memory stackHashes = new bytes32[](numStackItems);

    for (uint256 i = 0; i < numStackItems; ++i) {
      stackHashes[i] = keccak256(payload.stack[i]);
    }
    return keccak256(
      abi.encode(
        _PAYLOAD_TYPEHASH,
        payload.nonce,
        payload.deadline,
        keccak256(abi.encodePacked(payload.commands)),
        keccak256(abi.encodePacked(stackHashes))
      )
    );
  }
}
