// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "../interfaces/IRouter.sol";

contract Proxy {
  IRouter private immutable _router;

  constructor(address router_) {
    _router = IRouter(router_);

    (bool ok,) = _implementation().delegatecall(abi.encodeWithSignature("initialize()"));
    require(ok);
  }

  receive() external payable { }

  fallback() external payable {
    _delegate(_implementation());
  }

  function _implementation() internal view returns (address) {
    return _router.executorImpl();
  }

  function _delegate(address implementation) internal {
    assembly {
      calldatacopy(0, 0, calldatasize())

      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }
}
