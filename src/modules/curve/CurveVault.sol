// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "../../utils/ERC4626Staking.sol";
import "./ICurveGauge.sol";

contract CurveVault is ERC4626Staking {
  ICurveGauge public gauge;

  constructor(address gauge_, ERC20 token, ERC20 reward_, string memory name_, string memory symbol_)
    ERC4626Staking(token, reward_, name_, symbol_)
  {
    gauge = ICurveGauge(gauge_);
  }

  function totalAssets() public view override returns (uint256) {
    return gauge.balanceOf(address(this));
  }

  function afterDeposit(uint256 assets, uint256 shares) internal override {
    gauge.deposit(assets, address(this));

    super.afterDeposit(assets, shares);
  }

  function beforeWithdraw(uint256 assets, uint256 shares) internal override {
    gauge.withdraw(assets);

    return super.beforeWithdraw(assets, shares);
  }
}
