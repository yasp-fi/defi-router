// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @dev Collection of functions related to the address type
 * @author OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)
 */
library Address {
    error AddressInsufficientBalance(address account);
    error AddressEmptyCode(address target);
    error FailedInnerCall();

    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, defaultRevert);
    }

    function functionCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, customRevert);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, defaultRevert);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, defaultRevert);
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, defaultRevert);
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check if target is a contract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                if (target.code.length == 0) {
                    revert AddressEmptyCode(target);
                }
            }
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    function verifyCallResult(bool success, bytes memory returndata) internal view returns (bytes memory) {
        return verifyCallResult(success, returndata, defaultRevert);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    function defaultRevert() internal pure {
        revert FailedInnerCall();
    }

    function _revert(bytes memory returndata, function() internal view customRevert) private view {
        if (returndata.length > 0) {
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            customRevert();
            revert FailedInnerCall();
        }
    }
}