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
  function latestVault(address toke) external view returns (address);
}

interface IYVault {
  function token() external view returns (address);

  function withdraw(uint256 _shares) external returns (uint256);
  function withdraw(uint256 _shares, address recipient) external returns (uint256);
}

contract YearnModule is ModuleBase {
  address public immutable PARTNER_ID = address(0x0);
  IYPartnerTracker public immutable tracker;
  IYRegistry public immutable registry;

  constructor(address tracker_, address registry_, address weth) ModuleBase(weth) {
    tracker = IYPartnerTracker(tracker_);
    registry = IYRegistry(registry_);
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
}
