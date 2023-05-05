// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

abstract contract CompoundModule {
    function compound__provideLiquidity() public returns (uint256 amount) {}
    function compound__removeLiquidity() public returns (uint256 amount) {}
    function compound__collectRewards() public returns (uint256 rewardsAmount) {}
}
