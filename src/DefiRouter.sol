pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IExecutor.sol";
import "./utils/Proxy.sol";
import "./utils/EIP712.sol";
import "./utils/SignatureChecker.sol";
import "./utils/PayloadHash.sol";

contract DeFiRouter is IRouter, Owned, EIP712 {
  using SignatureChecker for address;
  using PayloadHash for IRouter.Payload;

  address public executorImpl;
  mapping(address => address) public executorOf;
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

  function getExecutorAddress(address owner_) external view returns (address) {
    return address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              bytes1(0xff),
              address(this),
              bytes32(bytes20((uint160(owner_)))),
              keccak256(abi.encodePacked(type(Proxy).creationCode, abi.encode(address(this))))
            )
          )
        )
      )
    );
  }

  function createExecutor(address owner_) public returns (address) {
    require(executorOf[owner_] == address(0), "Executor already created");

    bytes32 salt = bytes32(bytes20((uint160(owner_))));
    address executor = address(new Proxy{salt: salt}(address(this)));

    executorOf[owner_] = executor;

    emit NewExecutor(owner_, executor);

    return executor;
  }

  function execute(bytes32[] memory commands, bytes[] memory stack) external payable returns (bytes[] memory) {
    return _execute(msg.sender, commands, stack);
  }

  function executeFor(address user, IRouter.Payload memory payload, bytes calldata signature)
    external
    payable
    returns (bytes[] memory)
  {
    require(forwarders[msg.sender], "Permission denied");
    require(block.timestamp <= payload.deadline, "Signature was expired");

    _useUnorderedNonce(user, payload.nonce);
    user.verify(_hashTypedData(payload.hash()), signature);

    return _execute(user, payload.commands, payload.stack);
  }

  function _execute(address user, bytes32[] memory commands, bytes[] memory stack) internal returns (bytes[] memory) {
    address executor = executorOf[user];
    executor = executor == address(0) ? createExecutor(user) : executor;
    return IExecutor(executor).run{ value: msg.value }(commands, stack);
  }

  function _useUnorderedNonce(address from, uint256 nonce) internal {
    uint256 wordPos = uint248(nonce >> 8);
    uint256 bitPos = uint8(nonce);
    uint256 bit = 1 << bitPos;
    uint256 flipped = nonceBitmap[from][wordPos] ^= bit;

    require(!(flipped & bit == 0), "Invalid Nonce");
  }
}
