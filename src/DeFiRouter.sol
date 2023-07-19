// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/IRouter.sol";
import "./interfaces/IExecutor.sol";
import "./interfaces/IVerifier.sol";
import "./utils/Owned.sol";
import "./ExecutorProxy.sol";

contract DeFiRouter is IRouter, Owned {
  address public verifier;
  address public executorImpl;

  event ExecutorUpdated(address newImplementation);
  event VerifierUpdated(address newVerifier);

  event NewExecutor(address owner_, address executor_);

  constructor(address owner_, address verifier_, address executorImpl_)
    Owned(owner_)
  {
    executorImpl = executorImpl_;
    verifier = verifier_;
  }

  function updateExecutorImpl(address executorImpl_) external onlyOwner {
    require(executorImpl_.code.length > 0, "implementation is not contract");
    executorImpl = executorImpl_;
    emit ExecutorUpdated(executorImpl_);
  }

  function updateVerifier(address verifier_) external onlyOwner {
    verifier = verifier_;
    emit ExecutorUpdated(verifier_);
  }

  function executorOf(address owner_) public view returns (address) {
    bytes32 salt = bytes32(bytes20((uint160(owner_))));
    return address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              bytes1(0xff),
              address(this),
              salt,
              keccak256(
                abi.encodePacked(
                  type(ExecutorProxy).creationCode,
                  abi.encode(address(this)),
                  abi.encode(owner_)
                )
              )
            )
          )
        )
      )
    );
  }

  function createExecutor(address owner_) public returns (address) {
    if (executorOf(owner_).code.length > 0) {
      return executorOf(owner_);
    }

    bytes32 salt = bytes32(bytes20((uint160(owner_))));
    address executor =
      address(new ExecutorProxy{salt: salt}(address(this), owner_));

    emit NewExecutor(owner_, executor);

    return executor;
  }

  function execute(bytes calldata payload) external payable {
    _execute(msg.sender, payload);
  }

  function executeFor(
    uint48 nonce,
    uint48 deadline,
    address user,
    bytes calldata payload,
    bytes calldata signature
  ) external payable {
    IRouter.SignedTransaction memory signedTransaction = IRouter
      .SignedTransaction({
      nonce: nonce,
      deadline: deadline,
      user: user,
      caller: msg.sender,
      payload: payload
    });

    require(
      IVerifier(verifier).verify(signedTransaction, signature),
      "Verification failed"
    );
    _execute(user, payload);
  }

  function _execute(address user, bytes calldata payload) internal {
    address executor = createExecutor(user);
    IExecutor(executor).executePayload{ value: msg.value }(payload);
  }
}
