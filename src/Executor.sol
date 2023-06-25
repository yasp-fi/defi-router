// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "./interfaces/IExecutor.sol";
import "./utils/WeirollVM.sol";

contract Executor is IExecutor {
  using WeirollVM for bytes32[];

  address public immutable router;
  address internal _owner;

  event Initialize(address indexed owner);
  event Message(address indexed from, uint256 ethAmount, bytes data);

  constructor(address router_) {
    router = router_;
  }

  receive() external payable { }

  fallback() external payable {
    emit Message(msg.sender, msg.value, msg.data);
  }

  function initialize(address owner_) external {
    require(_owner == address(0), "Executor was already initialized");

    _owner = owner_;

    emit Initialize(owner_);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  function run(bytes32[] calldata commands, bytes[] memory state)
    external
    payable
    returns (bytes[] memory)
  {
    require(msg.sender == router, "Only router");
    return commands.execute(state);
  }
}
