// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import { IAllowanceTransfer } from "permit2/interfaces/IAllowanceTransfer.sol";
import { SafeCast160 } from "permit2/libraries/SafeCast160.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/tokens/ERC1155.sol";
import "../ModuleBase.sol";
import "../../utils/Constants.sol";

contract Permit2Module is ModuleBase {
  using SafeCast160 for uint256;

  IAllowanceTransfer public immutable PERMIT2;

  constructor(address permit2, address weth) ModuleBase(weth) {
    PERMIT2 = IAllowanceTransfer(permit2);
  }

  function permit(address from, IAllowanceTransfer.PermitSingle calldata permitSingle, bytes calldata signature) public {
    PERMIT2.permit(from, permitSingle, signature);
  }

  function permit(address from, IAllowanceTransfer.PermitBatch calldata permitBatch, bytes calldata signature) public {
    PERMIT2.permit(from, permitBatch, signature);
  }

  function permit2TransferFrom(address token, address from, address to, uint160 amount) public {
    PERMIT2.transferFrom(from, to, amount, token);
  }

  function permit2TransferFrom(IAllowanceTransfer.AllowanceTransferDetails[] memory batchDetails, address owner) public {
    uint256 batchLength = batchDetails.length;
    for (uint256 i = 0; i < batchLength; ++i) {
      require(batchDetails[i].from == owner, "Error: FromAddressIsNotOwner");
    }
    PERMIT2.transferFrom(batchDetails);
  }
}
