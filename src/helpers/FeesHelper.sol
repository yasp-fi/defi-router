pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "solmate/auth/Owned.sol";
import "../utils/Constants.sol";

contract FeesHelper is Owned {
  address public treasury;

  event FeeCollected(address indexed token, uint256 amount);

  constructor(address owner_, address treasury_) Owned(owner_) {
    treasury = treasury_;
  }

  function setTreasury(address newTreasury_) external onlyOwner {
    treasury = newTreasury_;
  }

  function pull(address token, address owner_, uint256 feeBps) external returns (uint256 restAmount) {
    uint256 availableFunds = IERC20(token).allowance(owner_, address(this));
    IERC20(token).transferFrom(owner_, address(this), availableFunds);
    if (feeBps > 0) {
      uint256 feeAmount = availableFunds * feeBps / Constants.MAX_BPS;
      IERC20(token).transfer(treasury, feeAmount);
      restAmount = availableFunds - feeAmount;
      emit FeeCollected(token, feeAmount);
    } else {
      restAmount = availableFunds;
    }
  }

  function sweep(address token, address owner_, uint256 feeBps) external {
    uint256 availableFunds = IERC20(token).balanceOf(address(this));
    if (feeBps > 0) {
      uint256 feeAmount = availableFunds * feeBps / Constants.MAX_BPS;
      IERC20(token).transfer(treasury, feeAmount);
      emit FeeCollected(token, feeAmount);
    }
    IERC20(token).transfer(owner_, IERC20(token).balanceOf(address(this)));
  }
}
