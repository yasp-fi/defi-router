pragma solidity ^0.8.13;

import "./PeripheryChecks.sol";
import "./PeripheryPermit2.sol";
import "./PeripheryPayments.sol";
import "./PeripheryImmutableState.sol";

contract PeripheryRouter is
  PeripheryPermit2,
  PeripheryChecks,
  PeripheryPayments
{
  constructor(ImmutableState memory state)
    PeripheryImmutableState(state)
  { }
}
