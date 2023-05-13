// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IMulticall {
  struct Instruction {
    address executable;
    bytes data;
  }
  /// @notice Call multiple functions and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param bundle The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data

  function multicall(Instruction[] calldata bundle)
    external
    payable
    returns (bytes[] memory results);
}

abstract contract Multicall is IMulticall {
  /// @inheritdoc IMulticall
  function multicall(Instruction[] calldata bundle)
    public
    payable
    override
    returns (bytes[] memory results)
  {
    results = new bytes[](bundle.length);

    for (uint256 i = 0; i < bundle.length; i++) {
      address executable = bundle[i].executable;
      bool success;
      bytes memory result;

      if (executable != address(this)) {
        (success, result) = executable.call{ value: msg.value }(bundle[i].data);
      } else {
        (success, result) = executable.delegatecall(bundle[i].data);
      }

      if (!success) {
        // Next 5 lines from https://ethereum.stackexchange.com/a/83577
        if (result.length < 68) revert();
        assembly {
          result := add(result, 0x04)
        }
        revert(abi.decode(result, (string)));
      }

      results[i] = result;
    }
  }
}
