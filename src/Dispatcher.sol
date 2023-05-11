// // SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.8.13;

// import "./base/PeripheryPermit2.sol";
// import "./modules/uniswapV3/UniswapV3Module.sol";
// import "./modules/aaveV3/AaveV3Module.sol";
// import "./modules/curve/CurveModule.sol";
// import "./utils/Locker.sol";
// import "./utils/BytesLib.sol";
// import "./Commands.sol";

// abstract contract SupportedModules is
//   PeripheryPermit2,
//   UniswapV3Module,
//   AaveV3Module,
//   CurveModule
// { }

// abstract contract Dispatcher is SupportedModules, Locker {
//   using BytesLib for bytes;

//   error InvalidCommandType(uint256 commandType);
//   error InvalidOwnerERC721();
//   error InvalidOwnerERC1155();
//   error BalanceTooLow();

//   /// @notice Decodes and executes the given command with the given inputs
//   /// @param commandType The command type to execute
//   /// @param inputs The inputs to execute the command with
//   /// @dev 2 masks are used to enable use of a nested-if statement in execution for efficiency reasons
//   /// @return success True on success of the command, false on failure
//   /// @return output The outputs or error messages, if any, from the command
//   function dispatch(bytes1 commandType, bytes calldata inputs)
//     internal
//     returns (bool success, bytes memory output)
//   {
//     uint256 command = uint8(commandType & Commands.COMMAND_TYPE_MASK);

//     success = true;

//     if (command < Commands.SECOND_IF_BOUNDARY) {
//       if (command < Commands.FIRST_IF_BOUNDARY) {
//         // 0x00 <= command < 0x10
//       } else {
//         // 0x10 <= command < 0x20
//       }
//     } else {
//       if (command < Commands.THIRD_IF_BOUNDARY) {
//         // 0x20 <= command < 0x30
//       } else {
//         // 0x30 <= command < 0x3f
//       }
//     }
//   }

//   /// @notice Executes encoded commands along with provided inputs.
//   /// @param commands A set of concatenated commands, each 1 byte in length
//   /// @param inputs An array of byte strings containing abi encoded inputs for each command
//   function execute(bytes calldata commands, bytes[] calldata inputs)
//     external
//     payable
//     virtual;

//   /// @notice Performs a call to purchase an ERC721, then transfers the ERC721 to a specified recipient
//   /// @param inputs The inputs for the protocol and ERC721 transfer, encoded
//   /// @param protocol The protocol to pass the calldata to
//   /// @return success True on success of the command, false on failure
//   /// @return output The outputs or error messages, if any, from the command
//   function callAndTransfer721(bytes calldata inputs, address protocol)
//     internal
//     returns (bool success, bytes memory output)
//   {
//     // equivalent: abi.decode(inputs, (uint256, bytes, address, address, uint256))
//     (uint256 value, bytes calldata data) = getValueAndData(inputs);
//     address recipient;
//     address token;
//     uint256 id;
//     assembly {
//       // 0x00 and 0x20 offsets are value and data, above
//       recipient := calldataload(add(inputs.offset, 0x40))
//       token := calldataload(add(inputs.offset, 0x60))
//       id := calldataload(add(inputs.offset, 0x80))
//     }
//     (success, output) = protocol.call{ value: value }(data);
//     if (success) {
//       ERC721(token).safeTransferFrom(address(this), map(recipient), id);
//     }
//   }

//   /// @notice Performs a call to purchase an ERC1155, then transfers the ERC1155 to a specified recipient
//   /// @param inputs The inputs for the protocol and ERC1155 transfer, encoded
//   /// @param protocol The protocol to pass the calldata to
//   /// @return success True on success of the command, false on failure
//   /// @return output The outputs or error messages, if any, from the command
//   function callAndTransfer1155(bytes calldata inputs, address protocol)
//     internal
//     returns (bool success, bytes memory output)
//   {
//     // equivalent: abi.decode(inputs, (uint256, bytes, address, address, uint256, uint256))
//     (uint256 value, bytes calldata data) = getValueAndData(inputs);
//     address recipient;
//     address token;
//     uint256 id;
//     uint256 amount;
//     assembly {
//       // 0x00 and 0x20 offsets are value and data, above
//       recipient := calldataload(add(inputs.offset, 0x40))
//       token := calldataload(add(inputs.offset, 0x60))
//       id := calldataload(add(inputs.offset, 0x80))
//       amount := calldataload(add(inputs.offset, 0xa0))
//     }
//     (success, output) = protocol.call{ value: value }(data);
//     if (success) {
//       ERC1155(token).safeTransferFrom(
//         address(this), map(recipient), id, amount, new bytes(0)
//       );
//     }
//   }

//   /// @notice Helper function to extract `value` and `data` parameters from input bytes string
//   /// @dev The helper assumes that `value` is the first parameter, and `data` is the second
//   /// @param inputs The bytes string beginning with value and data parameters
//   /// @return value The 256 bit integer value
//   /// @return data The data bytes string
//   function getValueAndData(bytes calldata inputs)
//     internal
//     pure
//     returns (uint256 value, bytes calldata data)
//   {
//     assembly {
//       value := calldataload(inputs.offset)
//     }
//     data = inputs.toBytes(1);
//   }
// }
