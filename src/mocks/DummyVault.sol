// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../utils/ERC4626Staking.sol";

contract DummyVault is ERC4626Staking {
  address public rewardRecipient;

  constructor(ERC20 token, ERC20 reward_, string memory name_, string memory symbol_)
    ERC4626Staking(token, reward_, name_, symbol_)
  { }

  function totalAssets() public view virtual override returns (uint256) {
    return asset.balanceOf(address(this));
  }

  function addRewards(uint256 amount) public {
    rewardsToken.transferFrom(msg.sender, address(this), amount);
    _addRewards(amount);
  }
}
