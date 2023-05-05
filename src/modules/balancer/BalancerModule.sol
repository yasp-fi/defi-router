// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

abstract contract BalancerModule {
    function balancer__swap() public returns (uint256 amount) {}
    function balancer__provideLiquidity() public returns (uint256 amount) {}
    function balancer__removeLiquidity() public returns (uint256 amount) {}
    function balancer__stake() public returns (uint256 stakeAmount) {}
    function balancer__unstake() public returns (uint256 stakeAmount) {}
    function balancer__collectRewards() public returns (uint256 rewardsAmount) {}
}
