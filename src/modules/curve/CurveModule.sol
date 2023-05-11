// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC4626.sol";
import "./ICurvePool.sol";

abstract contract CurveModule {
    function curveProvideLiquidity(address pool, uint8 coins, uint8 coinId, uint256 amount) public {
        ICurvePool curvePool = ICurvePool(pool);

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

    function curveRemoveLiquidity(address pool, uint8 coinId, uint256 amount) public {
        ICurvePool curvePool = ICurvePool(pool);

        try curvePool.remove_liquidity_one_coin(amount, coinId, 0) {}
        catch {
            curvePool.remove_liquidity_one_coin(amount, int128(int8(coinId)), 0);
        }
    }

    function curveStake(address gaugeVault, uint256 amount) public {
        IERC4626(gaugeVault).deposit(amount, address(this));
    }

    function curveUnstake(address gaugeVault, uint256 amount) public {
        IERC4626(gaugeVault).withdraw(amount, address(this), address(this));
    }

    function curve__collectRewards() public {}
    function curve__swap() public returns (uint256 amount) {}
}
