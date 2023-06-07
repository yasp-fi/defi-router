// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "../../utils/Constants.sol";
import "../ModuleBase.sol";

interface IYPartnerTracker {
  function token() external view returns (address);

  function deposit(address vault, address partnerId, uint256 amount) external returns (uint256);
}

interface IYRegistry {
  function latestVault(address token) external view returns (address);
}

interface IYVault {
  function token() external view returns (address);
  function pricePerShare() external view returns (uint256);
  function decimals() external view returns (uint256);

  function withdraw(uint256 _shares) external returns (uint256);
  function withdraw(uint256 _shares, address recipient) external returns (uint256);
}

interface IStakingRewards {
  function balanceOf(address owner) external view returns (uint256);
  function pendingReward(address owner) external view returns (uint256);
  function stakeFor(address recipient, uint256 amount) external;
}

contract YearnModule is ModuleBase {
  address public immutable PARTNER_ID;
  IYPartnerTracker public immutable tracker;
  IYRegistry public immutable registry;

  constructor(address tracker_, address registry_, address partner, address weth) ModuleBase(weth) {
    tracker = IYPartnerTracker(tracker_);
    registry = IYRegistry(registry_);
    PARTNER_ID = partner;
  }

  function positionOf(address user, address token) public view returns (uint256 amount, uint256 amountDeposited) {
    token = token == Constants.NATIVE_TOKEN ? address(WETH9) : token;
    address vault = registry.latestVault(token);

    amount = balanceOf(token, user);
    amountDeposited = balanceOf(vault, user);
    amountDeposited = convertShareToAsset(token, amountDeposited);
  }

  function positionOf(address user, address token, address stakingPool)
    public
    view
    returns (uint256 amount, uint256 amountDeposited, uint256 amountStaked, uint256 pendingRewards)
  {
    token = token == Constants.NATIVE_TOKEN ? address(WETH9) : token;
    (amount, amountDeposited) = positionOf(user, token);
    amountStaked = IStakingRewards(stakingPool).balanceOf(user);
    amountStaked = convertShareToAsset(token, amountStaked);
    pendingRewards = IStakingRewards(stakingPool).pendingReward(user);
  }

  function depositAndStake(address stakingPool, address token, uint256 amount)
    public
    payable
    returns (uint256 sharesStaked)
  {
    address vault = registry.latestVault(token);
    sharesStaked = deposit(token, amount);
    IERC20(vault).approve(stakingPool, sharesStaked);
    IStakingRewards(stakingPool).stakeFor(msg.sender, sharesStaked);
  }

  function deposit(address token, uint256 amount) public payable returns (uint256 sharesAdded) {
    if (token == Constants.NATIVE_TOKEN) {
      amount = wrapETH(amount);
      token = address(WETH9);
    }
    amount = balanceOf(token, amount);

    address vault = registry.latestVault(token);
    IERC20(token).approve(address(tracker), amount);
    sharesAdded = IYPartnerTracker(tracker).deposit(vault, PARTNER_ID, amount);

    _sweepToken(vault);
  }

  function withdraw(address token, uint256 amount) public payable returns (uint256 assets) {
    if (token == Constants.NATIVE_TOKEN) {
      token = address(WETH9);
    }

    address vault = registry.latestVault(token);
    amount = balanceOf(vault, amount);

    try IYVault(vault).withdraw(amount, address(this)) returns (uint256 amountRemoved_) {
      assets = amountRemoved_;
    } catch {
      assets = IYVault(vault).withdraw(amount);
    }

    if (token == Constants.NATIVE_TOKEN) {
      unwrapWETH9(amount);
    }

    _sweepToken(IYVault(vault).token());
  }

  function convertShareToAsset(address token, uint256 amount) internal view returns (uint256) {
    IYVault vault = IYVault(registry.latestVault(token));
    return amount * vault.pricePerShare() / 10 ** vault.decimals();
  }
}
