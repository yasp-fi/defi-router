pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import "./utils/Constants.sol";

interface IRegistry {
  function halted() external view returns (bool);
  function modules(address) external view returns (bytes32);
  function isValidModule(address module) external view returns (bool);
}

contract Registry is IRegistry, Owned {
  mapping(address => bytes32) public modules;

  event ModuleRegistered(address indexed registration, bytes32 info);
  event ModuleUnregistered(address indexed registration);
  event Halted();
  event Unhalted();

  bool public halted;

  modifier isNotHalted() {
    require(!halted, "Halted");
    _;
  }

  modifier isHalted() {
    require(halted, "Not halted");
    _;
  }

  constructor(address owner) Owned(owner) { }

  function halt() external isNotHalted onlyOwner {
    halted = true;
    emit Halted();
  }

  function unhalt() external isHalted onlyOwner {
    halted = false;
    emit Unhalted();
  }

  function isValidModule(address handler) external view override returns (bool) {
    return modules[handler] != 0 && modules[handler] != Constants.DEPRECATED;
  }

  function registerModule(address moduleAddr, bytes32 info) external onlyOwner {
    require(moduleAddr != address(0), "zero address");
    require(info != Constants.DEPRECATED, "unregistered info");
    require(modules[moduleAddr] != Constants.DEPRECATED, "unregistered");
    modules[moduleAddr] = info;
    emit ModuleRegistered(moduleAddr, info);
  }

  function unregisterModule(address moduleAddr) external onlyOwner {
    require(moduleAddr != address(0), "zero address");
    require(modules[moduleAddr] != bytes32(0), "no registration");
    require(modules[moduleAddr] != Constants.DEPRECATED, "unregistered");
    modules[moduleAddr] = Constants.DEPRECATED;
    emit ModuleUnregistered(moduleAddr);
  }
}
