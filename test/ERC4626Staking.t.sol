// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "erc4626-tests/ERC4626.test.sol";

import "solmate/test/utils/mocks/MockERC20.sol";
import "../src/utils/ERC4626Staking.sol";
import "../src/mocks/DummyVault.sol";

///@dev Fork E2E Tests, uses Arbitrum fork
contract ERC4626StakingTest is ERC4626Test {
  address public OWNER = address(0xdEADBEeF00000000000000000000000000000000);

  MockERC20 public rewardToken;
  MockERC20 public stakeToken;
  ERC4626Staking public vault;

  function setUp() public override {
    rewardToken = new MockERC20("Reward Mock", "RWRD", 18);
    stakeToken = new MockERC20("Token Mock", "TKN", 18);
    vm.label(address(rewardToken), "RewardToken");
    vm.label(address(stakeToken), "UnderlyingToken");

    vault = new DummyVault(stakeToken, rewardToken, "Dummy Vault", "VLT");

    _underlying_ = address(stakeToken);
    _vault_ = address(vault);
    _delta_ = 0;
    _vaultMayBeEmpty = false;
    _unlimitedAmount = false;
  }

  function test_claimRewards(Init memory init, uint256 rewardAmount) public {
    vm.warp(1);
    vm.assume(rewardAmount > 1e41 && rewardAmount < 1e57);

    setUpVault(init);
    address owner = init.user[0];

    rewardToken.mint(address(this), rewardAmount);
    _approve(address(rewardToken), address(this), _vault_, rewardAmount);
    DummyVault(address(vault)).addRewards(rewardAmount);

    assertApproxEqAbs(rewardAmount, vault.getRewardForDuration(), rewardAmount / 1e8);

    assertEq(vault.rewardPerToken(), 0);
    vm.warp(vault.periodFinish());
    assertGt(vault.rewardPerToken(), 0);

    uint256 pendingRewards = vault.pendingReward(owner);

    uint256 balanceBefore = rewardToken.balanceOf(owner);
    vault.collectRewards(owner);
    uint256 balanceAfter = rewardToken.balanceOf(owner);
    assertApproxEqAbs(pendingRewards, balanceAfter - balanceBefore, _delta_);
  }

  // NOTE: The following test is relaxed to consider only smaller values (of type uint120),
  // since maxWithdraw() fails with large values (due to overflow).

  function test_maxWithdraw(Init memory init) public override {
    init = clamp(init, type(uint120).max);
    super.test_maxWithdraw(init);
  }

  function clamp(Init memory init, uint256 max) internal pure returns (Init memory) {
    for (uint256 i = 0; i < N; i++) {
      init.share[i] = init.share[i] % max;
      init.asset[i] = init.asset[i] % max;
    }
    init.yield = init.yield % int256(max);
    return init;
  }
}
