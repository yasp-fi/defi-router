// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/interfaces/IERC20.sol";
import "./interfaces/IVerifier.sol";
import "./utils/EIP712.sol";
import "./libs/SignatureChecker.sol";
import "./libs/LibHash.sol";
import "./utils/Owned.sol";

contract PermitVerifier is IVerifier, EIP712 {
  using SignatureChecker for address;
  using LibHash for IRouter.SignedTransaction;

  address public immutable router;

  mapping(address => mapping(uint256 => uint256)) public nonceBitmap;

  modifier onlyRouter() {
    require(msg.sender == router, "Only router");
    _;
  }

  constructor(address router_) {
    router = router_;
  }

  function verify(
    address caller,
    IRouter.SignedTransaction memory signedTransaction,
    bytes calldata signature
  ) public onlyRouter returns (bool permitted) {
    validatePayload(caller, signedTransaction);

    signedTransaction.user.verify(
      _hashTypedData(signedTransaction.hash()), signature
    );

    return true;
  }

  function validatePayload(
    address caller,
    IRouter.SignedTransaction memory transaction
  ) internal {
    require(transaction.caller == caller, "Invalid caller");
    require(block.timestamp <= transaction.deadline, "Signature was expired");
    uint256 nonce = transaction.nonce;
    address from = transaction.user;

    ///@notice added for "automated" transaction execution
    if (nonce == 0) return;

    uint256 wordPos = uint248(nonce >> 8);
    uint256 bitPos = uint8(nonce);

    uint256 bit = 1 << bitPos;
    uint256 flipped = nonceBitmap[from][wordPos] ^= bit;

    require(flipped & bit != 0, "Invalid Nonce");
  }
}
