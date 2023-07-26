// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/interfaces/IERC20.sol";
import "../src/PermitVerifier.sol";
import "../src/Executor.sol";
import "../src/DeFiRouter.sol";

contract DeFiRouterScript is Script {
  function run() public returns (DeFiRouter deployed) {
    bytes32 salt = keccak256(bytes("I love you"));
    address deployAddress = address(0x01C7b26177c676A1b92Bef2E101616Ca5CA62918);
    uint256 deployerPrivateKey = uint256(vm.envBytes32(("PRIVATE_KEY")));

    address broadcaster = vm.addr(deployerPrivateKey);

    console2.log("broadcaster", broadcaster);
    console2.log("DeFiRouter deploy address", deployAddress);

    vm.startBroadcast(deployerPrivateKey);

    // tx 1 - Deploy Executor Implementation ~ 412332 gas
    Executor executor = new Executor(address(deployAddress));
    // tx 2 - Deploy Permit Verifier ~ 619145 gas
    PermitVerifier verifier = new PermitVerifier(address(deployAddress));
    // tx 3 - Deploy DeFiRouter ~ 1123076 gas
    deployed = new DeFiRouter{salt: salt}(
      broadcaster, address(executor), address(verifier)
    );

    vm.stopBroadcast();
  }
}
