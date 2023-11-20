// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/interfaces/IERC20.sol";
import "../src/helpers/VelocoreSwapper.sol";

contract FeesHelperScript is Script {
  function run() public returns (VelocoreSwapper deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32(("PRIVATE_KEY")));

    address broadcaster = vm.addr(deployerPrivateKey);
    address vault = address(0x1d0188c4B276A09366D05d6Be06aF61a73bC7535);
    
    console2.log("broadcaster", broadcaster);

    vm.startBroadcast(deployerPrivateKey);

    deployed = new VelocoreSwapper(broadcaster, broadcaster, vault, 75);

    vm.stopBroadcast();
  }
}
