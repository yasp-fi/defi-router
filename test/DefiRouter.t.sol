// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DefiRouter.sol";

contract CounterTest is Test {
    DefiRouter public router;

    function setUp() public {
        address WETH = address(0);
        router = new DefiRouter(WETH);
    }
}
