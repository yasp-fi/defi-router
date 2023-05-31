// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "solmate/mixins/ERC4626.sol";

abstract contract ERC4626Staking is ERC4626 {
  uint256 public constant DURATION = 6 hours;
  ERC20 public rewardsToken;

  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public lastUpdateTime = 0;
  uint256 public rewardPerTokenStored = 0;
  uint256 public pendingRewards = 0;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  event UpdateRewards(uint256 newRewards);
  event CollectRewards(address indexed user, uint256 reward);

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  constructor(ERC20 token, ERC20 reward_, string memory name_, string memory symbol_) ERC4626(token, name_, symbol_) {
    rewardsToken = reward_;
  }

  function lastTimeRewardApplicable() public view virtual returns (uint256) {
    return block.timestamp < periodFinish ? block.timestamp : periodFinish;
  }

  function rewardPerToken() public view virtual returns (uint256) {
    if (totalAssets() == 0) {
      return rewardPerTokenStored;
    }
    uint256 timeDiff = lastTimeRewardApplicable() - lastUpdateTime;
    uint256 rewardDelta = timeDiff * rewardRate * 1e18 / totalAssets();
    return rewardPerTokenStored + rewardDelta;
  }

  function pendingReward(address account) public view virtual returns (uint256 pendingReward_) {
    uint256 userBalance = balanceOf[account];
    uint256 rewardRateDiff = rewardPerToken() - userRewardPerTokenPaid[account];
    pendingReward_ = userBalance * rewardRateDiff / 1e18;
  }

  function earned(address account) public view virtual returns (uint256) {
    return rewards[account] + pendingReward(account);
  }

  function getRewardForDuration() external view virtual returns (uint256) {
    return rewardRate * DURATION;
  }

  function collectRewards(address user) public updateReward(user) {
    uint256 reward = rewards[user];
    if (reward > 0) {
      rewards[user] = 0;
      rewardsToken.transfer(user, reward);
      emit CollectRewards(user, reward);
    }
  }

  function onNewRewards(uint256 newRewards) internal {
    pendingRewards += newRewards;
  }

  function updateRewards() public updateReward(address(0)) {
    uint256 reward = pendingRewards;
    require(reward > 0, "Zero rewards");

    if (block.timestamp >= periodFinish) {
      rewardRate = reward / DURATION;
    } else {
      uint256 remaining = periodFinish - block.timestamp;
      uint256 leftover = remaining * rewardRate;
      rewardRate = (reward + leftover) / DURATION;
    }

    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 balance = rewardsToken.balanceOf(address(this));
    require(rewardRate <= balance / DURATION, "Provided reward too high");

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp + DURATION;
    pendingRewards = 0;
    emit UpdateRewards(reward);
  }
}
