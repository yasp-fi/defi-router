// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "../../utils/Constants.sol";
import "../ModuleBase.sol";

interface IYPartnerTracker {
  function token() external view returns (address);

  function deposit(address vault, address partnerId, uint256 amount) external;
}

interface IYVaultV2 {
  function token() external view returns (address);

  function withdraw(uint256 _shares) external;
}

interface IYVaultV3 {
  function token() external view returns (address);

  function withdraw(uint256 _shares, address recipient) external;
}


contract YearnModule is ModuleBase {
  address public immutable PARTNER_ID = address(0x0);
  IYPartnerTracker public immutable tracker;

  constructor(address tracker_, address weth) ModuleBase(weth) {
    tracker = IYPartnerTracker(tracker_);
  }

  function deposit(address vault, uint256 value) public payable returns (uint256 shares) {
    address asset = IYVaultV2(vault).token();
    value = balanceOf(asset, value);

    IERC20(asset).approve(vault, value);
    IYPartnerTracker(tracker).deposit(vault, PARTNER_ID, value);

    _sweepToken(vault);
  }

  function withdraw(address vault, uint256 value) public payable returns (uint256 shares) {
    try IYVaultV3(vault).withdraw(value, address(this)) { }
    catch {
      IYVaultV2(vault).withdraw(value);
    }

    _sweepToken(IYVaultV2(vault).token());

  }
}
