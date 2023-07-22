// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../utils/EIP712.sol";
import "./IRouter.sol";

interface IVerifier {
  function verify(
    address caller,
    IRouter.SignedTransaction memory signedTransaction,
    bytes calldata signature
  ) external returns (bool permitted);
}
