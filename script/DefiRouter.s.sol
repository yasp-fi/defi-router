// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/interfaces/IERC20.sol";
import "../src/PermitVerifier.sol";
import "../src/Executor.sol";
import "../src/DeFiRouter.sol";

contract DeFiRouterScript is Script {
  function run() public returns (DeFiRouter deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32(("PRIVATE_KEY")));

    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);

    vm.startBroadcast(deployerPrivateKey);

    // tx 1 - Deploy DeFiRouter ~ 949738 gas
    deployed = new DeFiRouter(
      broadcaster, address(0), address(0)
    );
    // tx 2 - Deploy Executor Implementation ~ 694547 gas
    Executor executor = new Executor(address(deployed));
    // tx 3 - Deploy Permit Verifier ~ 619145 gas
    PermitVerifier verifier = new PermitVerifier(address(deployed));
    // tx 4 - Update Executor ~ 49735 gas
    deployed.updateExecutorImpl(address(executor));
    // tx 5 - Update Permit Verifier ~ 49811 gas
    deployed.updateVerifier(address(verifier));
    vm.stopBroadcast();
  }
}
