// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/interfaces/IERC20.sol";
import "../src/helpers/FeesHelper.sol";

contract FeesHelperScript is Script {
  function run() public returns (FeesHelper deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32(("PRIVATE_KEY")));

    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);

    vm.startBroadcast(deployerPrivateKey);

    deployed = new FeesHelper(broadcaster, broadcaster);

    vm.stopBroadcast();
  }
}
