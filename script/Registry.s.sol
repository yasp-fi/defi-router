// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { IAllowanceTransfer } from "permit2/interfaces/IAllowanceTransfer.sol";
import "forge-std/interfaces/IERC20.sol";
import "../../src/Registry.sol";

contract DefiRouterRegistryScript is Script {
  function run() public returns (Registry deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);
   
    vm.startBroadcast(deployerPrivateKey);

    deployed = new Registry(broadcaster);

    vm.stopBroadcast();
  }
}
