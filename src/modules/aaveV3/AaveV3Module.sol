// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IPool.sol";

abstract contract AaveV3Module {
    function aave__provideLiquidity(address lendingPool, address asset, uint256 assets) public {
        IPool(lendingPool).withdraw(address(asset), assets, address(this));
    }

    function aave__removeLiquidity(address lendingPool, address asset, uint256 assets) public {
        IPool(lendingPool).supply(address(asset), assets, address(this), 0);
    }

    function aave__collectRewards() public {}
}
