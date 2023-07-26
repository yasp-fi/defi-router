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
  uint256 public baseFee = 15000;

  event ExecutorUpdated(address newImplementation);
  event VerifierUpdated(address newVerifier);
  event BaseFeeUpdated(uint256 newBaseFee);

  event NewExecutor(address owner_, address executor_);
  event GasRefund(
    address owner_,
    address caller_,
    address gasToken,
    uint256 gasPrice,
    uint256 gasUsed,
    uint256 amountPaid
  );

  constructor(address owner_, address executorImpl_, address verifier_)
    Owned(owner_)
  { 
    executorImpl = executorImpl_;
    verifier = verifier_;
  }

  function updateBaseFee(uint256 baseFee_) external onlyOwner {
    baseFee = baseFee_;
    emit BaseFeeUpdated(baseFee_);
  }

  function updateExecutorImpl(address executorImpl_) external onlyOwner {
    require(executorImpl_.code.length > 0, "implementation is not a contract");
    executorImpl = executorImpl_;
    emit ExecutorUpdated(executorImpl_);
  }

  function updateVerifier(address verifier_) external onlyOwner {
    require(verifier_.code.length > 0, "Verifier is not a contract");
    verifier = verifier_;
    emit VerifierUpdated(verifier_);
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
    IRouter.SignedTransaction memory signedTransaction,
    bytes calldata signature
  ) external payable {
    uint256 initialGas = gasleft();

    createExecutor(signedTransaction.user);

    require(
      IVerifier(verifier).verify(msg.sender, signedTransaction, signature),
      "Verification failed"
    );

    _execute(signedTransaction.user, signedTransaction.payload);
    _payGas(signedTransaction, initialGas - gasleft() + baseFee);
  }

  function _payGas(
    IRouter.SignedTransaction memory signedTransaction,
    uint256 gasUsed
  ) internal {
    address user = signedTransaction.user;
    uint256 gasPrice = signedTransaction.gasPrice;
    address gasToken = signedTransaction.gasToken;
    address executor = executorOf(user);

    ///@notice skip sponsored transactions gas refund
    if (gasPrice == 0) return;

    uint256 amountPaid =
      IExecutor(executor).payGas(msg.sender, gasUsed, gasToken, gasPrice);

    emit GasRefund(user, msg.sender, gasToken, gasPrice, gasUsed, amountPaid);
  }

  function _execute(address user, bytes memory payload) internal {
    address executor = executorOf(user);
    IExecutor(executor).executePayload{ value: msg.value }(payload);
  }
}
