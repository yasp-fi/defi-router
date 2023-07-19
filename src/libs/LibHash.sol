// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../interfaces/IRouter.sol";

library LibHash {
  bytes32 public constant _SIGNED_TRANSACTION_TYPEHASH = keccak256(
    "SignedTransaction(address user,uint48 nonce,address caller,uint48 deadline,bytes payload)"
  );

  function hash(IRouter.SignedTransaction memory transaction)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encode(
        _SIGNED_TRANSACTION_TYPEHASH,
        abi.encodePacked(transaction.user),
        transaction.nonce,
        abi.encodePacked(transaction.caller),
        transaction.deadline,
        keccak256(abi.encodePacked(transaction.payload))
      )
    );
  }
}
