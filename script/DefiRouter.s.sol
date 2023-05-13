// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/DefiRouter.sol";

contract DefiRouterScript is Script {
  address PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
  address WETH = address(vm.envAddress("WETH"));

  function run() public returns (DefiRouter deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

    vm.startBroadcast(deployerPrivateKey);
    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);

    ImmutableState memory state =
      ImmutableState({ permit2: PERMIT2, weth9: WETH });

    deployed = new DefiRouter(state);

    vm.stopBroadcast();
  }
}
