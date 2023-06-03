// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "../../utils/ERC4626Staking.sol";
import "./IStargateLPStaking.sol";
import "./StargateRegistry.sol";

contract StargateVault is ERC4626Staking {
  IStargateLPStaking public staking;
  uint256 public poolStakingId;

  constructor(address registry_, ERC20 token, ERC20 reward_, string memory name_, string memory symbol_)
    ERC4626Staking(token, reward_, name_, symbol_)
  {
    staking = StargateRegistry(registry_).staking();
    poolStakingId = StargateRegistry(registry_).getStakingId(address(token));
  }

  function totalAssets() public view override returns (uint256) {
    IStargateLPStaking.UserInfo memory info = staking.userInfo(poolStakingId, address(this));
    return info.amount;
  }

  function beforeWithdraw(uint256 assets, uint256 shares) internal override {
    /// -----------------------------------------------------------------------
    /// Withdraw assets from Stargate
    /// -----------------------------------------------------------------------
    uint256 balanceBefore = rewardsToken.balanceOf(address(this));

    staking.withdraw(poolStakingId, assets);

    _addRewards(rewardsToken.balanceOf(address(this)) - balanceBefore);

    return super.beforeWithdraw(assets, shares);
  }

  function afterDeposit(uint256 assets, uint256 shares) internal override {
    /// -----------------------------------------------------------------------
    /// Deposit assets into Stargate
    /// -----------------------------------------------------------------------
    uint256 balanceBefore = rewardsToken.balanceOf(address(this));

    asset.approve(address(staking), assets);
    staking.deposit(poolStakingId, assets);

    _addRewards(rewardsToken.balanceOf(address(this)) - balanceBefore);

    super.afterDeposit(assets, shares);
  }

  function maxWithdraw(address owner_) public view override returns (uint256) {
    uint256 cash = asset.balanceOf(address(staking));

    uint256 assetsBalance = convertToAssets(this.balanceOf(owner_));

    return cash < assetsBalance ? cash : assetsBalance;
  }

  function maxRedeem(address owner_) public view override returns (uint256) {
    uint256 cash = asset.balanceOf(address(staking));

    uint256 cashInShares = convertToShares(cash);

    uint256 shareBalance = this.balanceOf(owner_);

    return cashInShares < shareBalance ? cashInShares : shareBalance;
  }
}
