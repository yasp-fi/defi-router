// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import { ISignatureTransfer } from "permit2/interfaces/ISignatureTransfer.sol";
import { IAllowanceTransfer } from "permit2/interfaces/IAllowanceTransfer.sol";
import { SafeCast160 } from "permit2/libraries/SafeCast160.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/tokens/ERC1155.sol";
import "../ModuleBase.sol";
import "../../utils/Constants.sol";

interface IPermit2 is ISignatureTransfer, IAllowanceTransfer {
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

contract Permit2Module is ModuleBase {
  using SafeCast160 for uint256;

  IPermit2 public immutable PERMIT2;

  constructor(address permit2, address weth) ModuleBase(weth) {
    PERMIT2 = IPermit2(permit2);
  }

  function permitTransfer(
    IPermit2.PermitTransferFrom memory permit,
    IPermit2.SignatureTransferDetails memory details,
    bytes memory signature
  ) public payable {
    require(details.to == address(this), "Error: ToAddressIsNotRouter");
    PERMIT2.permitTransferFrom(permit, details, msg.sender, signature);
  }

  function permitTransferBatch(
    IPermit2.PermitBatchTransferFrom memory permit,
    IPermit2.SignatureTransferDetails[] calldata details,
    bytes calldata signature
  ) public payable {
    for (uint256 i = 0; i < details.length; ++i) {
      require(details[i].to == address(this), "Error: ToAddressIsNotRouter");
    }
    PERMIT2.permitTransferFrom(permit, details, msg.sender, signature);
  }
}
