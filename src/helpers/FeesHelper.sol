pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "solmate/auth/Owned.sol";

contract FeesHelper is Owned {
  uint256 constant MAX_BPS = 10000;

  address public treasury;

  event FeeCollected(address indexed token, uint256 amount);

  constructor(address owner_, address treasury_) Owned(owner_) {
    treasury = treasury_;
  }

  function setTreasury(address newTreasury_) external onlyOwner {
    treasury = newTreasury_;
  }

  function pay(address token, uint256 feeBps) public returns (uint256 feeAmount, uint256 restAmount) {
    require(feeBps <= MAX_BPS, "BPS > 10000");
    uint256 availableFunds = IERC20(token).balanceOf(address(this));
    feeAmount = availableFunds * feeBps / MAX_BPS;
    restAmount = availableFunds - feeAmount;

    IERC20(token).transfer(treasury, feeAmount);
    emit FeeCollected(token, feeAmount);
  }

  function pull(address token, address holder, uint256 feeBps) external returns (uint256 amountPulled) {
    uint256 availableFunds = IERC20(token).allowance(holder, address(this));
    IERC20(token).transferFrom(holder, address(this), availableFunds);
    if (feeBps > 0) {
      (, amountPulled) = pay(token, feeBps);
    } else {
      amountPulled = availableFunds;
    }
  }

  function sweep(address token, address receiver, uint256 feeBps) external returns (uint256 amountSweeped) {
    if (feeBps > 0) {
      (, amountSweeped) = pay(token, feeBps);
    } else {
      amountSweeped = IERC20(token).balanceOf(address(this));
    }
    IERC20(token).transfer(receiver, amountSweeped);
  }
}
