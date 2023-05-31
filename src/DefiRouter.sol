// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import "./utils/LibStack.sol";
import "./utils/LibCalldata.sol";
import "./Executor.sol";
import "./Registry.sol";

contract DefiRouter is Executor {
  using LibStack for bytes32[];
  using LibCalldata for bytes;

  IRegistry public immutable registry;
  bytes32[] internal stack;

  event Sweep(address indexed token, address indexed receiver, uint256 amount);

  constructor(address _registry) {
    registry = IRegistry(_registry);
  }

  function execute(address[] memory modules, bytes32[] memory configs, bytes[] memory payloads)
    external
    payable
    isNotHalted
  {
    _beforeExecute();
    _execute(modules, configs, payloads);
    _afterExecute();
  }

  function _isHalted() internal view virtual override returns (bool) {
    return registry.halted();
  }

  function _validateTarget(address module) internal view virtual override returns (bool) {
    return registry.isValidModule(module);
  }

  function _validateCallback(address callbackAddr) internal view virtual override returns (bool) {
    return registry.isValidCallback(callbackAddr);
  }

  function _getCallackTarget(address callbackAddr) internal view virtual override returns (address) {
    return address(bytes20(registry.callbacks(callbackAddr)));
  }

  function _beforeExecute() internal { }

  function _afterExecute() internal {
    while (stack.length > 0) {
      bytes4 signature = stack.popSig();
      if (signature == Constants.SWEEP_SIG) {
        _sweep(stack.popAddress(), msg.sender, 0);
      } else if (signature == Constants.POSTPROCESS_SIG) {
        bytes memory data = abi.encodeWithSelector(Constants.POSTPROCESS_SIG);
        data.exec(stack.popAddress(), type(uint256).max);
      } else {
        revert("Invalid signature");
      }
    }
    if (address(this).balance > 0) {
      SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }
  }

  function _sweep(address token, address recipient, uint256 amountMinimum) internal {
    uint256 balance = ERC20(token).balanceOf(address(this));
    require(balance >= amountMinimum, "Error: Insufficient ERC20 balance");

    if (balance > 0) {
      SafeTransferLib.safeTransfer(ERC20(token), recipient, balance);
      emit Sweep(token, recipient, balance);
    }
  }
}
