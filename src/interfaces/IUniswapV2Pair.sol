// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IUniswapV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
