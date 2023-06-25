// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import { IAllowanceTransfer } from "permit2/interfaces/IAllowanceTransfer.sol";
import "forge-std/interfaces/IERC20.sol";
import "../src/DeFiRouter.sol";
import "../src/Executor.sol";

contract DefiRouterScript is Script {
  function run() public returns (DeFiRouter deployed) {
    uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONIC"), 0);

    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);

    vm.startBroadcast(deployerPrivateKey);

    deployed = new DeFiRouter(broadcaster, address(0));
    Executor executor = new Executor(address(deployed));
    deployed.updateExecutorImpl(address(executor));

    vm.stopBroadcast();
  }
}
