// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./Executor.sol";
import "./Registry.sol";

contract DefiRouter is Executor {
  IRegistry public immutable registry;

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

  function callbackExecute(address[] memory modules, bytes32[] memory configs, bytes[] memory payloads)
    external
    payable
    isNotHalted
  {
    require(msg.sender == address(this), "Error: Does not allow external calls");
    _execute(modules, configs, payloads);
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

  function _afterExecute() internal { }
}
