// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/interfaces/IERC20.sol";
import "../src/DeFiRouter.sol";
import "../src/Executor.sol";

contract DeFiRouterScript is Script {
  function run() public returns (DeFiRocuter deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32(("PRIVATE_KEY")));

    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);

    vm.startBroadcast(deployerPrivateKey);

    deployed = new DeFiRouter(broadcaster);
    Executor executor = new Executor(address(deployed));
    deployed.updateExecutorImpl(address(executor));

    vm.stopBroadcast();
  }
}
