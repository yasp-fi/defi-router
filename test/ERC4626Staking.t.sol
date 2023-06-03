// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "../src/utils/ERC4626Staking.sol";
import "../src/mocks/DummyVault.sol";

///@dev Fork E2E Tests, uses Arbitrum fork
contract ERC4626StakingTest is Test {
  address public OWNER = address(0xdEADBEeF00000000000000000000000000000000);

  MockERC20 public rewardToken;
  MockERC20 public stakeToken;
  ERC4626Staking public vault;

  modifier withActor(address actor, uint64 balance) {
    vm.assume(balance > 1e8);
    vm.assume(actor != address(0));

    deal(address(stakeToken), actor, uint256(balance));
    vm.startPrank(actor);
    _;
    vm.stopPrank();
  }

  function setUp() public {
    rewardToken = new MockERC20("Reward Mock", "RWRD", 18);
    stakeToken = new MockERC20("Token Mock", "TKN", 18);
    vault = new DummyVault(stakeToken, rewardToken, "Dummy Vault", "VLT");
  }
}
