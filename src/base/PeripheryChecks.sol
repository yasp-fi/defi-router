pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC721.sol";
import "forge-std/interfaces/IERC1155.sol";
import "forge-std/interfaces/IERC20.sol";

abstract contract PeripheryChecks {
  function checkERC721Owner(address owner, address token, uint256 id)
    public
    view
  {
    require(
      IERC721(token).ownerOf(id) == owner, "Error: invalid owner for ERC721"
    );
  }

  function checkERC1155Balance(
    address owner,
    address token,
    uint256 id,
    uint256 minBalance
  ) public view {
    require(
      IERC1155(token).balanceOf(owner, id) >= minBalance,
      "Error: invalid balance for ERC1155"
    );
  }

  function checkERC20Balance(address owner, address token, uint256 minBalance)
    public
    view
  {
    require(
      IERC20(token).balanceOf(owner) >= minBalance,
      "Error: invalid balance for ERC20"
    );
  }
}
