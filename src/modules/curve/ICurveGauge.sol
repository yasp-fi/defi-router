// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ICurveMinter {
  function allowed_to_mint_for(address addr, address _for) external view returns (bool);
  function mint(address gauge_addr) external;
  function mint_for(address gauge_addr, address _for) external;
  function toggle_approve_mint(address minting_user) external;
}

interface ICurveGauge {
  function lp_token() external view returns (address);
  function balanceOf(address arg0) external view returns (uint256);

  function set_approve_deposit(address addr, bool can_deposit) external;
  function deposit(uint256 _value, address addr) external;
  function withdraw(uint256 _value) external;
  function transfer(address _to, uint256 _value) external returns (bool);
  function claimable_tokens(address addr) external view returns (uint256);
}
