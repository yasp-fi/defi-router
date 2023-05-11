// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

abstract contract BalancerModule {
    function balancerSwap() public returns (uint256 amount) {}
    function balancerProvideLiquidity() public returns (uint256 amount) {}
    function balancerRemoveLiquidity() public returns (uint256 amount) {}
    function balancerStake() public returns (uint256 stakeAmount) {}
    function balancerUnstake() public returns (uint256 stakeAmount) {}
    function balancerCollectRewards() public returns (uint256 rewardsAmount) {}
}
