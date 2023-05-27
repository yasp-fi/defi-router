// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "../ModuleBase.sol";
import "./ICurveGauge.sol";

contract CurveGaugeModule is ModuleBase {
  constructor(address weth) ModuleBase(weth) { }

  function deposit(address gaugeAddress, address receiver, uint256 _value) external {
    ICurveGauge gauge = ICurveGauge(gaugeAddress);
    // address token = gauge.lp_token();
    gauge.deposit(_value, receiver);
    // try gauge.deposit(_value, receiver) { }
    // catch Error(string memory reason) {
    // _revertMsg("deposit", reason);
    // } catch {
    // _revertMsg("deposit");
    // }
    // _tokenApproveZero(token, gaugeAddress);
  }

  function withdraw(address gaugeAddress, uint256 _value) external returns (uint256) {
    ICurveGauge gauge = ICurveGauge(gaugeAddress);
    address token = gauge.lp_token();
    gauge.withdraw(_value);
    // try gauge.withdraw(_value) { }
    // catch Error(string memory reason) {
    // _revertMsg("withdraw", reason);
    // } catch {
    // _revertMsg("withdraw");
    // }

    // _updateToken(token);

    return _value;
  }
}
