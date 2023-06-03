// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "solmate/mixins/ERC4626.sol";
import "../../utils/Constants.sol";
import "../../utils/ERC4626Staking.sol";
import "../ModuleBase.sol";

contract ERC4626Module is ModuleBase {
  constructor(address weth) ModuleBase(weth) { }

  function deposit(address vault, uint256 value) public payable returns (uint256 shares) {
    address asset = address(ERC4626(vault).asset());
    value = balanceOf(asset, value);

    IERC20(asset).approve(vault, value);
    shares = ERC4626(vault).deposit(value, address(this));

    _sweepToken(vault);
  }

  function withdraw(address vault, uint256 value) public payable returns (uint256 shares) {
    shares = ERC4626(vault).withdraw(value, address(this), address(this));

    _sweepToken(address(ERC4626(vault).asset()));
  }

  function collectRewards(address vault, address owner) public payable returns (uint256 rewardsCollected) {
    rewardsCollected = ERC4626Staking(vault).collectRewards(owner);

    _sweepToken(address(ERC4626Staking(vault).rewardsToken()));
  }
}
