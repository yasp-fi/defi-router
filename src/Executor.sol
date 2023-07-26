// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/IExecutor.sol";
import "./interfaces/IRouter.sol";
import "forge-std/interfaces/IERC20.sol";

contract Executor is IExecutor {
  address public immutable router;
  address internal _owner;

  // Flashloan callback
  // 0 - None, 1 - Aave, 2 - Balancer
  uint8 internal _expectCallbackId;

  event Initialize(address indexed owner);

  modifier onlyRouter() {
    require(msg.sender == router, "Only router");
    _;
  }

  modifier expectedCallback(uint8 callbackId) {
    require(_expectCallbackId == callbackId, "Callback call denied");
    _;
    _expectCallbackId = 0;
  }

  constructor(address router_) {
    router = router_;
  }

  receive() external payable { }

  function owner() public view returns (address) {
    return _owner;
  }

  function initialize(address owner_) external {
    require(_owner == address(0), "Executor was already initialized");

    _owner = owner_;

    emit Initialize(owner_);
  }

  function setCallback(uint8 callbackId) public {
    require(msg.sender == address(this), "Callback permission denied");
    _expectCallbackId = callbackId;
  }

  function executePayload(bytes memory payload) external payable onlyRouter {
    _executeBatch(payload);
  }

  function payGas(
    address caller,
    uint256 gasUsed,
    address gasToken,
    uint256 gasPrice
  ) external onlyRouter returns (uint256 amountPaid) {
    amountPaid = gasUsed * gasPrice;
    IERC20(gasToken).transfer(caller, amountPaid);
  }

  function _executeBatch(bytes memory payload) internal {
    // 
    assembly {
      let length := mload(payload)
      let i := 0x20
      for { } lt(i, length) { } {
        let operation := shr(0xf8, mload(add(payload, i)))
        let to := shr(0x60, mload(add(payload, add(i, 0x01))))
        let value := mload(add(payload, add(i, 0x15)))
        let dataLength := mload(add(payload, add(i, 0x35)))
        let data := add(payload, add(i, 0x55))
        let success := 0
        switch operation
        case 0 { success := call(gas(), to, value, data, dataLength, 0, 0) }
        case 1 { success := delegatecall(gas(), to, data, dataLength, 0, 0) }
        if eq(success, 0) {
          let errorLength := returndatasize()
          returndatacopy(0, 0, errorLength)
          revert(0, errorLength)
        }
        i := add(i, add(0x55, dataLength))
      }
    }
  }

  //@notice Aave flashloan callback
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address, // initiator
    bytes calldata params
  ) external expectedCallback(1) returns (bool) {
    address pool = msg.sender;
    _executeBatch(params);

    for (uint256 i = 0; i < assets.length; i++) {
      IERC20 asset = IERC20(assets[i]);
      uint256 amountOwing = amounts[i] + premiums[i];

      require(asset.balanceOf(address(this)) >= amountOwing, "Invalid Balance");
      asset.approve(pool, amountOwing);
    }

    return true;
  }

  ///@notice Balancer flashloan callback
  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external expectedCallback(2) {
    address vault = msg.sender;
    _executeBatch(userData);

    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20 asset = tokens[i];
      uint256 amountOwing = amounts[i] + feeAmounts[i];

      require(asset.balanceOf(address(this)) >= amountOwing, "Invalid Balance");
      asset.transfer(vault, amountOwing);
    }
  }
}
