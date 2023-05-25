// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/DefiRouter.sol";

contract DefiRouterScript is Script {
  address PERMIT2 = address(vm.envAddress("PERMIT2"));
  address WETH = address(vm.envAddress("WETH"));

  function run() public returns (DefiRouter deployed) {
    uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONIC"), 0);

    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);
    
    vm.startBroadcast(deployerPrivateKey);

    ImmutableState memory state =
      ImmutableState({ permit2: PERMIT2, weth9: WETH });

    deployed = new DefiRouter(state);

    vm.stopBroadcast();
  }
}
