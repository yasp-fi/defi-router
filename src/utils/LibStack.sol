// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

library LibStack {
  function peek(bytes32[] storage _stack) internal view returns (bytes32 ret) {
    uint256 length = _stack.length;
    require(length > 0, "stack empty");
    ret = _stack[length - 1];
  }

  function peek(bytes32[] storage _stack, uint256 _index) internal view returns (bytes32 ret) {
    uint256 length = _stack.length;
    require(length > 0, "stack empty");
    require(length > _index, "not enough elements in stack");
    ret = _stack[length - _index - 1];
  }

  function pushRaw(bytes32[] storage _stack, bytes32 _input) internal {
    _stack.push(_input);
  }

  function pushAddress(bytes32[] storage _stack, address _input) internal {
    pushRaw(_stack, bytes32(uint256(uint160(_input))));
  }

  function pushSig(bytes32[] storage _stack, bytes4 signature) internal {
    pushRaw(_stack, bytes32(signature));
  }

  function popRaw(bytes32[] storage _stack) internal returns (bytes32 ret) {
    ret = peek(_stack);
    _stack.pop();
  }

  function popAddress(bytes32[] storage _stack) internal returns (address ret) {
    ret = address(uint160(uint256(peek(_stack))));
    _stack.pop();
  }

  function popSig(bytes32[] storage _stack) internal returns (bytes4 ret) {
    ret = bytes4(peek(_stack));
    _stack.pop();
  }
}
