// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/IRouter.sol";
import "./interfaces/IExecutor.sol";
import "./utils/Owned.sol";
import "./utils/EIP712.sol";
import "./utils/SignatureChecker.sol";
import "./utils/PayloadHash.sol";
import "./ExecutorProxy.sol";

contract DeFiRouter is IRouter, Owned, EIP712 {
  using SignatureChecker for address;
  using PayloadHash for IRouter.Payload;

  address public executorImpl;
  mapping(address => bool) public forwarders;
  mapping(address => mapping(uint256 => uint256)) public nonceBitmap;

  event NewExecutor(address owner_, address executor_);
  event ForwarderUpdated(address forwarder, bool status);
  event ExecutorUpdated(address newImplementation);

  constructor(address owner_, address executorImpl_) Owned(owner_) {
    executorImpl = executorImpl_;
  }

  function updateForwarder(address forwarder, bool status) external onlyOwner {
    forwarders[forwarder] = status;
    emit ForwarderUpdated(forwarder, status);
  }

  function updateExecutorImpl(address executorImpl_) external onlyOwner {
    require(executorImpl_.code.length > 0, "implementation is not contract");
    executorImpl = executorImpl_;
    emit ExecutorUpdated(executorImpl_);
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
    address executor = address(new ExecutorProxy{salt: salt}(address(this), owner_));

    emit NewExecutor(owner_, executor);

    return executor;
  }

  function execute(bytes32[] memory commands, bytes[] memory state)
    external
    payable
    returns (bytes[] memory)
  {
    return _execute(msg.sender, commands, state);
  }

  function executeFor(
    bytes32[] memory commands,
    bytes[] memory state,
    bytes32 metadata,
    bytes memory signature
  ) external returns (bytes[] memory) {
    require(forwarders[msg.sender], "Invalid forwarder");

    uint48 nonce = uint48(bytes6(metadata));
    uint48 deadline = uint48(bytes6(metadata << 48));
    address user = address(bytes20(metadata << 96));

    require(block.timestamp <= deadline, "Signature was expired");

    _useUnorderedNonce(user, nonce);

    IRouter.Payload memory payload = IRouter.Payload({
      nonce: nonce,
      deadline: deadline,
      user: user,
      commands: commands,
      state: state
    });

    user.verify(_hashTypedData(payload.hash()), signature);

    return _execute(user, commands, state);
  }

  function _execute(
    address user,
    bytes32[] memory commands,
    bytes[] memory state
  ) internal returns (bytes[] memory) {
    address executor = createExecutor(user);
    return IExecutor(executor).run{ value: msg.value }(commands, state);
  }

  function _useUnorderedNonce(address from, uint256 nonce) internal {
    uint256 wordPos = uint248(nonce >> 8);
    uint256 bitPos = uint8(nonce);
    uint256 bit = 1 << bitPos;
    uint256 flipped = nonceBitmap[from][wordPos] ^= bit;

    require(!(flipped & bit == 0), "Invalid Nonce");
  }
}
