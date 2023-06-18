// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "../utils/LibConfig.sol";
import "../utils/Constants.sol";

library LibCalldata {
  using LibConfig for bytes32;

  function getSelector(bytes memory data) internal pure returns (bytes4 selector) {
    selector = data[0] | (bytes4(data[1]) >> 8) | (bytes4(data[2]) >> 16) | (bytes4(data[3]) >> 24);
  }

  function adjust(bytes memory data, bytes32 config, bytes32[256] memory refArray, uint256 refLimit) internal pure {
    require(!config.isStatic(), "Config is static, dynamic config required");
    // Fetch the parameter configuration from config
    uint256 base = Constants.BIPS_BASE;
    (uint256[] memory refs, uint256[] memory offsets) = config.getDynamicParams();

    // Trim the data with the reference and parameters
    for (uint256 i = 0; i < refs.length; i++) {
      require(refs[i] < refLimit, "Reference index is out of range");
      bytes32 value = refArray[refs[i]];
      uint256 offset = offsets[i];

      assembly {
        let loc := add(add(data, 0x20), offset)
        let m := mload(loc)
        // dynamic fraction parameter logic
        // Adjust the value by multiplier if a dynamic parameter is not zero
        if iszero(iszero(m)) {
          // Assert no overflow first
          let p := mul(m, value)
          if iszero(eq(div(p, m), value)) { revert(0, 0) } // require(p / m == value)
          value := div(p, base)
        }
        mstore(loc, value)
      }
    }
  }
}
