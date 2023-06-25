// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "../interfaces/IRouter.sol";

library PayloadHash {
  bytes32 public constant _PAYLOAD_TYPEHASH = keccak256(
    "Payload(uint48 nonce,uint48 deadline,address user,bytes32[] commands, bytes[] state)"
  );
  function hash(IRouter.Payload memory payload) internal pure returns (bytes32) {
    uint256 numStackItems = payload.state.length;
    bytes32[] memory stateHashes = new bytes32[](numStackItems);

    for (uint256 i = 0; i < numStackItems; ++i) {
      stateHashes[i] = keccak256(payload.state[i]);
    }
    return keccak256(
      abi.encode(
        _PAYLOAD_TYPEHASH,
        payload.nonce,
        payload.deadline,
        abi.encodePacked(payload.user),
        keccak256(abi.encodePacked(payload.commands)),
        keccak256(abi.encodePacked(stateHashes))
      )
    );
  }
}
