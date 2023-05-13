// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC4626.sol";
import "./ICurvePool.sol";
import "../../utils/Constants.sol";

abstract contract CurveModule {
  function curveGetLiquidityToken(address pool)
    public
    view
    returns (IERC20 lpToken)
  {
    ICurvePool curvePool = ICurvePool(pool);

    try curvePool.token() returns (address lpTokenAddress) {
      lpToken = IERC20(lpTokenAddress);
    } catch {
      lpToken = IERC20(address(pool));
    }
  }

  function curveGetToken(address pool, uint8 index) public view returns (address) {
    ICurvePool curvePool = ICurvePool(pool);

    try curvePool.coins(index) returns (address token) {
      return token;
    } catch {
      try curvePool.coins(int128(int8(index))) returns (address token) {
        return token;
      } catch {
        return address(0);
      }
    }
  }

  function curveCoins(address pool) public view returns (uint8 count) {
    for (count = 2; curveGetToken(pool, count) != address(0); count++) { }
  }

  function curveCoinId(address pool, address token) public view returns (uint8 index) {
    for (index = 0; curveGetToken(pool, index) != token; index++) { }
  }

  function curveProvideLiquidity(address pool, address token, uint256 amount)
    public
  {
    ICurvePool curvePool = ICurvePool(pool);
    uint8 coins = curveCoins(pool);
    uint8 coinId = curveCoinId(pool, token);

    amount = amount == Constants.MAX_BALANCE
      ? IERC20(token).balanceOf(address(this))
      : amount;

    if (coins == 2) {
      uint256[2] memory coinsAmount;
      coinsAmount[coinId] = amount;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, (expectedLp * 99) / 100);
    }

    if (coins == 3) {
      uint256[3] memory coinsAmount;
      coinsAmount[coinId] = amount;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, (expectedLp * 99) / 100);
    }

    if (coins == 4) {
      uint256[4] memory coinsAmount;
      coinsAmount[coinId] = amount;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, (expectedLp * 99) / 100);
    }

    if (coins == 5) {
      uint256[5] memory coinsAmount;
      coinsAmount[coinId] = amount;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, (expectedLp * 99) / 100);
    }

    if (coins == 6) {
      uint256[6] memory coinsAmount;
      coinsAmount[coinId] = amount;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, (expectedLp * 99) / 100);
    }
  }

  function curveRemoveLiquidity(address pool, address token, uint256 amount)
    public
  {
    ICurvePool curvePool = ICurvePool(pool);
    uint8 coinId = curveCoinId(pool, token);

    amount = amount == Constants.MAX_BALANCE
      ? curveGetLiquidityToken(pool).balanceOf(address(this))
      : amount;

    try curvePool.remove_liquidity_one_coin(amount, coinId, 0) { }
    catch {
      curvePool.remove_liquidity_one_coin(amount, int128(int8(coinId)), 0);
    }
  }

  function curveStake(address gaugeVault, uint256 amount, address receiver)
    public
  {
    IERC4626(gaugeVault).deposit(amount, receiver);
  }

  function curveUnstake(address gaugeVault, uint256 amount, address receiver)
    public
  {
    IERC4626(gaugeVault).withdraw(amount, receiver, address(this));
  }

  function curveCollectRewards() public { }
  function curveSwap() public returns (uint256 amount) { }
}
