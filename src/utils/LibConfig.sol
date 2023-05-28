// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "../utils/Constants.sol";

library LibConfig {
  function isStatic(bytes32 conf) internal pure returns (bool) {
    return conf & Constants.STATIC_MASK == 0;
  }

  function isDynamic(bytes32 conf) internal pure returns (bool) {
    return !isStatic(conf);
  }

  function isReferenced(bytes32 conf) internal pure returns (bool) {
    return getReturnSize(conf) != 0;
  }

  function getReturnSize(bytes32 conf) internal pure returns (uint256) {
    return uint256((conf & Constants.RETURN_SIZE_MASK) >> Constants.RETURN_SIZE_OFFSET);
  }

  function getDynamicParams(bytes32 conf) internal pure returns (uint256[] memory refs, uint256[] memory offsets) {
    require(!isStatic(conf), "Static params");
    uint256 refCount = Constants.REFS_COUNT_LIMIT;
    while (conf & Constants.REFS_MASK == Constants.REFS_MASK && refCount > 0) {
      refCount--;
      conf = conf >> 8;
    }
    require(refCount > 0, "No dynamic params");
    refs = new uint256[](refCount);
    offsets = new uint256[](refCount);

    // parse refs
    for (uint256 i = 0; i < refCount; i++) {
      refs[i] = uint256(conf & Constants.REFS_MASK);
      conf = conf >> 8;
    }

    // parse offsets
    uint256 offsetCount = 0;
    for (uint256 i = 0; i < Constants.OFFSETS_COUNT_LIMIT; i++) {
      if (conf & Constants.OFFSETS_MASK != 0) {
        require(offsetCount < refCount, "Offset count exceeds ref count");
        offsets[offsetCount++] = i * 32 + 4;
      }

      conf = conf >> 1;
    }
    require(offsetCount == refCount, "Offset count less than ref count");
  }

  function buildStatic(uint8 returnSize) internal pure returns (bytes32 conf) {
    conf |= bytes32(uint256(returnSize) << Constants.RETURN_SIZE_OFFSET);
  }

  function buildDynamic(uint8 returnSize, uint8[] memory locs, uint8[] memory refs)
    internal
    pure
    returns (bytes32 conf)
  {
    require(locs.length == refs.length, "inconsistent length");
    // set config as dynamic
    conf |= Constants.STATIC_MASK;
    // set return data
    conf |= bytes32(uint256(returnSize) << Constants.RETURN_SIZE_OFFSET);

    // set indexes in payload data where bytes32 gonna be modified
    uint256 loc;
    for (uint256 i = 0; i < locs.length; i++) {
      loc |= 1 << locs[i];
    }
    conf |= bytes32(uint256(loc) << Constants.LOCATION_OFFSET);

    // set ref table indexes
    uint256 ref;
    for (uint256 i = 0; i < Constants.REFS_COUNT_LIMIT; i++) {
      uint256 val = i < refs.length ? uint256(refs[i]) : 0xff;
      ref |= val << ((Constants.REFS_COUNT_LIMIT - i - 1) * 8);
    }
    conf |= bytes32(ref);
  }
}
