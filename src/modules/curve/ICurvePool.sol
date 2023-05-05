// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ICurvePool {
  function token() external view returns (address);
  function coins(uint256) external view returns (address);
  function coins(int128) external view returns (address);
  function is_killed() external view returns (bool);
  function get_virtual_price() external view returns (uint256);

  function price_oracle() external view returns (uint256);

  function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
    external
    payable;

  function add_liquidity(
    uint256[2] memory amounts,
    uint256 min_mint_amount,
    bool _use_underlying
  ) external payable returns (uint256);

  function add_liquidity(
    uint256[3] memory amounts,
    uint256 min_mint_amount,
    bool _use_underlying
  ) external payable returns (uint256);

  function add_liquidity(address pool, uint256[4] memory amounts, uint256 min_mint_amount)
    external;

  function add_liquidity(
    uint256[4] memory amounts,
    uint256 min_mint_amount,
    bool _use_underlying
  ) external payable returns (uint256);

  function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
    external
    payable;

  function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
    external
    payable;
  function add_liquidity(uint256[5] memory amounts, uint256 min_mint_amount)
    external
    payable;
  function add_liquidity(uint256[6] memory amounts, uint256 min_mint_amount)
    external
    payable;

  function remove_liquidity_imbalance(
    uint256[2] calldata amounts,
    uint256 max_burn_amount
  ) external;

  function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;

  function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 min_amount)
    external;
  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount)
    external;

  function exchange(int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount)
    external;

  function exchange(
    uint256 from,
    uint256 to,
    uint256 _from_amount,
    uint256 _min_to_amount,
    bool use_eth
  ) external;

  function balances(uint256) external view returns (uint256);

  function get_dy(int128 from, int128 to, uint256 _from_amount)
    external
    view
    returns (uint256);

  function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit)
    external
    view
    returns (uint256);

  function calc_token_amount(uint256[] calldata _amounts, bool _is_deposit)
    external
    view
    returns (uint256);

  function calc_token_amount(
    address _pool,
    uint256[4] calldata _amounts,
    bool _is_deposit
  ) external view returns (uint256);

  function calc_token_amount(uint256[5] calldata _amounts, bool _is_deposit)
    external
    view
    returns (uint256);

  function calc_token_amount(uint256[6] calldata _amounts, bool _is_deposit)
    external
    view
    returns (uint256);

  function calc_token_amount(uint256[4] calldata _amounts, bool _is_deposit)
    external
    view
    returns (uint256);

  function calc_token_amount(uint256[3] calldata _amounts, bool _is_deposit)
    external
    view
    returns (uint256);

  function calc_withdraw_one_coin(uint256 amount, uint256 i)
    external
    view
    returns (uint256);
  function calc_withdraw_one_coin(uint256 amount, int128 i)
    external
    view
    returns (uint256);
}
