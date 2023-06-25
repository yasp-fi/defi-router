// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1271 {
  /// @dev Should return whether the signature provided is valid for the provided data
  /// @param hash      Hash of the data to be signed
  /// @param signature Signature byte array associated with _data
  /// @return magicValue The bytes4 magic value 0x1626ba7e
  function isValidSignature(bytes32 hash, bytes memory signature)
    external
    view
    returns (bytes4 magicValue);
}

library SignatureChecker {
  bytes32 constant UPPER_BIT_MASK =
    (0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

  function verify(address claimedSigner, bytes32 hash, bytes memory signature)
    internal
    view
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    if (claimedSigner.code.length == 0) {
      if (signature.length == 65) {
        (r, s) = abi.decode(signature, (bytes32, bytes32));
        v = uint8(signature[64]);
      } else if (signature.length == 64) {
        // EIP-2098
        bytes32 vs;
        (r, vs) = abi.decode(signature, (bytes32, bytes32));
        s = vs & UPPER_BIT_MASK;
        v = uint8(uint256(vs >> 255)) + 27;
      } else {
        revert("Invalid signature length");
      }
      address signer = ecrecover(hash, v, r, s);
      if (signer == address(0)) revert("Invalid signature");
      if (signer != claimedSigner) revert("Invalid signer");
    } else {
      bytes4 magicValue =
        IERC1271(claimedSigner).isValidSignature(hash, signature);
      if (magicValue != IERC1271.isValidSignature.selector) {
        revert("Invalid contract signature");
      }
    }
  }
}
