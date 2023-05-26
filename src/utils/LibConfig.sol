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
    (uint256 refCount, bytes32 nextConf) = _trimUnusedRefs(conf);
    (refs, nextConf) = _parseRefs(nextConf, refCount);
    (offsets,) = _parseOffsets(nextConf, refCount);
  }

  function _trimUnusedRefs(bytes32 conf) internal pure returns (uint256 refCount, bytes32) {
    refCount = Constants.REFS_COUNT_LIMIT;
    while (conf & Constants.REFS_MASK == Constants.REFS_MASK && refCount > 0) {
      refCount--;
      conf = conf >> 8;
    }
    require(refCount > 0, "No dynamic params");
    return (refCount, conf);
  }

  function _parseRefs(bytes32 conf, uint256 refCount) internal pure returns (uint256[] memory refs, bytes32) {
    for (uint256 i = 0; i < refCount; i++) {
      refs[i] = uint256(conf & Constants.REFS_MASK);
      conf = conf >> 8;
    }
    return (refs, conf);
  }

  function _parseOffsets(bytes32 conf, uint256 refCount) internal pure returns (uint256[] memory offsets, bytes32) {
    uint256 offsetCount = 0;

    for (uint256 i = 0; i < Constants.OFFSETS_COUNT_LIMIT; i++) {
      if (conf & Constants.OFFSETS_MASK != 0) {
        require(offsetCount < refCount, "Offset count exceeds ref count");
        offsets[offsetCount++] = i * 32 + 4;
      }

      conf = conf >> 1;
    }
    require(offsetCount == refCount, "Offset count less than ref count");
    return (offsets, conf);
  }
}
