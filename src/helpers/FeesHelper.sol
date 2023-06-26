// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/interfaces/IERC20.sol";
import "../utils/Owned.sol";

contract FeesHelper is Owned {
  uint256 constant MAX_BPS = 10000;

  address public treasury;

  event FeeCollected(
    address indexed payer, address indexed token, uint256 amount
  );

  constructor(address owner_, address treasury_) Owned(owner_) {
    treasury = treasury_;
  }

  function setTreasury(address newTreasury_) external onlyOwner {
    treasury = newTreasury_;
  }

  function pay(address token, address payer, uint256 feeBps)
    public
    returns (uint256 feeAmount, uint256 restAmount)
  {
    require(feeBps <= MAX_BPS, "BPS > 10000");
    uint256 availableFunds;
    if (payer != address(this)) {
      availableFunds = IERC20(token).allowance(payer, address(this));
    } else {
      availableFunds = IERC20(token).balanceOf(address(this));
    }
    feeAmount = availableFunds * feeBps / MAX_BPS;
    restAmount = availableFunds - feeAmount;

    IERC20(token).transferFrom(payer, treasury, feeAmount);
    emit FeeCollected(payer, token, feeAmount);
  }

  function pull(address token, address holder)
    external
    returns (uint256 amountPulled)
  {
    amountPulled = IERC20(token).allowance(holder, address(this));
    IERC20(token).transferFrom(holder, address(this), amountPulled);
  }

  function sweep(address token, address receiver)
    external
    returns (uint256 amountSweeped)
  {
    amountSweeped = IERC20(token).balanceOf(address(this));
    IERC20(token).transfer(receiver, amountSweeped);
  }
}
