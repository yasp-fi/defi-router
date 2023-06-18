pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IExecutor.sol";
import "./utils/Constants.sol";
import "./utils/Proxy.sol";

contract DeFiRouter is IRouter, Owned {
  address public executorImpl;

  mapping(address user => address executor) public executorOf;

  event NewExecutor(address owner_, address executor_);
  event ExecutorUpdate();

  constructor(address owner_, address executorImpl_) Owned(owner_) {
    executorImpl = executorImpl_;
  }

  function updateExecutorImpl(address executorImpl_) external onlyOwner {
    require(executorImpl_.code.length > 0, "implementation is not contract");
    executorImpl = executorImpl_;
    emit ExecutorUpdate();
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
    address executor = address(new Proxy{salt:salt}(address(this)));

    executorOf[owner_] = executor;

    emit NewExecutor(owner_, executor);

    return executor;
  }

  function execute(bytes32[] calldata commands, bytes[] memory stack) external payable {
    address executor = executorOf[msg.sender];
    executor = executor == address(0) ? createExecutor(msg.sender) : executor;
    IExecutor(executor).run{ value: msg.value }(commands, stack);
  }
}
