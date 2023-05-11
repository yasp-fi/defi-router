// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

abstract contract CompoundModule {
    function compoundProvideLiquidity() public returns (uint256 amount) {}
    function compoundRemoveLiquidity() public returns (uint256 amount) {}
    function compoundCollectRewards() public returns (uint256 rewardsAmount) {}
}
