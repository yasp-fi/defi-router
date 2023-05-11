pragma solidity ^0.8.13;

import "./Constants.sol";

contract Locker {
    error ContractLocked();

    address internal lockedBy = Constants.NOT_LOCKED_FLAG;

    modifier isNotLocked() {
        if (msg.sender != address(this)) {
            if (lockedBy != Constants.NOT_LOCKED_FLAG) revert ContractLocked();
            lockedBy = msg.sender;
            _;
            lockedBy = Constants.NOT_LOCKED_FLAG;
        } else {
            _;
        }
    }

    /// @notice Calculates the recipient address for a command
    /// @param recipient The recipient or recipient-flag for the command
    /// @return output The resultant recipient for the command
    function map(address recipient) internal view returns (address) {
        if (recipient == Constants.MSG_SENDER) {
            return lockedBy;
        } else if (recipient == Constants.ADDRESS_THIS) {
            return address(this);
        } else {
            return recipient;
        }
    }
}