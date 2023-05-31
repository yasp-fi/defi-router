// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import "./ICurvePool.sol";
import "./ICurveGauge.sol";
import "../../utils/Constants.sol";
import "../../utils/LibCalldata.sol";
import "../ModuleBase.sol";

contract CurveModule is ModuleBase {
  using LibCalldata for bytes;

  constructor(address weth) ModuleBase(weth) { }

  function addLiquidity(
    address curvePool,
    address lpToken,
    address[] calldata tokens,
    uint256[] calldata amounts,
    uint256 minPoolAmount
  ) public payable returns (uint256) {
    (uint256[] memory _amounts, uint256 balanceBefore, uint256 ethAmount) =
      _addLiquidityBefore(curvePool, lpToken, tokens, amounts);

    // Execute add_liquidity according to amount array size
    if (_amounts.length == 2) {
      uint256[2] memory amts = [_amounts[0], _amounts[1]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(amts, minPoolAmount);
    } else if (_amounts.length == 3) {
      uint256[3] memory amts = [_amounts[0], _amounts[1], _amounts[2]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(amts, minPoolAmount);
    } else if (_amounts.length == 4) {
      uint256[4] memory amts = [_amounts[0], _amounts[1], _amounts[2], _amounts[3]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(amts, minPoolAmount);
    } else if (_amounts.length == 5) {
      uint256[5] memory amts = [_amounts[0], _amounts[1], _amounts[2], _amounts[3], _amounts[4]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(amts, minPoolAmount);
    } else if (_amounts.length == 6) {
      uint256[6] memory amts = [_amounts[0], _amounts[1], _amounts[2], _amounts[3], _amounts[4], _amounts[5]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(amts, minPoolAmount);
    } else {
      revert("Error: Invalid amount[] size");
    }

    return _addLiquidityAfter(curvePool, lpToken, tokens, amounts, balanceBefore);
  }

  /// @notice Curve add liquidity with underlying true flag
  function addLiquidityUnderlying(
    address curvePool,
    address lpToken,
    address[] calldata tokens,
    uint256[] calldata amounts,
    uint256 minPoolAmount
  ) public payable returns (uint256) {
    (uint256[] memory _amounts, uint256 balanceBefore, uint256 ethAmount) =
      _addLiquidityBefore(curvePool, lpToken, tokens, amounts);

    // Execute add_liquidity according to amount array size
    if (_amounts.length == 2) {
      uint256[2] memory amts = [_amounts[0], _amounts[1]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(amts, minPoolAmount, true);
    } else if (_amounts.length == 3) {
      uint256[3] memory amts = [_amounts[0], _amounts[1], _amounts[2]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(amts, minPoolAmount, true);
    } else if (_amounts.length == 4) {
      uint256[4] memory amts = [_amounts[0], _amounts[1], _amounts[2], _amounts[3]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(amts, minPoolAmount, true);
    } else if (_amounts.length == 5) {
      uint256[5] memory amts = [_amounts[0], _amounts[1], _amounts[2], _amounts[3], _amounts[4]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(amts, minPoolAmount, true);
    } else if (_amounts.length == 6) {
      uint256[6] memory amts = [_amounts[0], _amounts[1], _amounts[2], _amounts[3], _amounts[4], _amounts[5]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(amts, minPoolAmount, true);
    } else {
      revert("invalid amount[] size");
    }

    return _addLiquidityAfter(curvePool, lpToken, tokens, amounts, balanceBefore);
  }

  /// @notice Curve add liquidity with factory zap
  function addLiquidityFactoryZap(
    address curvePool,
    address lpToken,
    address[] calldata tokens,
    uint256[] calldata amounts,
    uint256 minPoolAmount
  ) public payable returns (uint256) {
    (uint256[] memory _amounts, uint256 balanceBefore, uint256 ethAmount) =
      _addLiquidityBefore(curvePool, lpToken, tokens, amounts);

    // Execute add_liquidity according to amount array size
    if (_amounts.length == 3) {
      uint256[3] memory amts = [_amounts[0], _amounts[1], _amounts[2]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(lpToken, amts, minPoolAmount);
    } else if (_amounts.length == 4) {
      uint256[4] memory amts = [_amounts[0], _amounts[1], _amounts[2], _amounts[3]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(lpToken, amts, minPoolAmount);
    } else if (_amounts.length == 5) {
      uint256[5] memory amts = [_amounts[0], _amounts[1], _amounts[2], _amounts[3], _amounts[4]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(lpToken, amts, minPoolAmount);
    } else if (_amounts.length == 6) {
      uint256[6] memory amts = [_amounts[0], _amounts[1], _amounts[2], _amounts[3], _amounts[4], _amounts[5]];
      ICurvePool(curvePool).add_liquidity{ value: ethAmount }(lpToken, amts, minPoolAmount);
    } else {
      revert("invalid amount[] size");
    }

    return _addLiquidityAfter(curvePool, lpToken, tokens, amounts, balanceBefore);
  }

  function removeLiquidityOneCoin(
    address curvePool,
    address lpToken,
    address tokenI,
    uint256 lpTokenAmount,
    uint256 i,
    uint256 minAmount
  ) public payable returns (uint256) {
    (uint256 _lpTokenAmount, uint256 balanceBefore) =
      _removeLiquidityOneCoinBefore(curvePool, lpToken, tokenI, lpTokenAmount);
    try ICurvePool(curvePool).remove_liquidity_one_coin(_lpTokenAmount, i, minAmount) { }
    catch {
      ICurvePool(curvePool).remove_liquidity_one_coin(_lpTokenAmount, int128(uint128(i)), minAmount);
    }

    return _removeLiquidityOneCoinAfter(curvePool, lpToken, tokenI, balanceBefore);
  }

  function removeLiquidityOneCoinUnderlying(
    address curvePool,
    address lpToken,
    address tokenI,
    uint256 lpTokenAmount,
    uint256 i,
    uint256 minAmount
  ) public payable returns (uint256) {
    (uint256 _lpTokenAmount, uint256 balanceBefore) =
      _removeLiquidityOneCoinBefore(curvePool, lpToken, tokenI, lpTokenAmount);
    try ICurvePool(curvePool).remove_liquidity_one_coin(_lpTokenAmount, i, minAmount, true) { }
    catch {
      ICurvePool(curvePool).remove_liquidity_one_coin(_lpTokenAmount, int128(uint128(i)), minAmount, true);
    }

    return _removeLiquidityOneCoinAfter(curvePool, lpToken, tokenI, balanceBefore);
  }

  /// @notice Curve remove liquidity one coin with with factory zap
  function removeLiquidityOneCoinFactoryZap(
    address curvePool,
    address lpToken,
    address tokenI,
    uint256 lpTokenAmount,
    int128 i,
    uint256 minAmount
  ) public payable returns (uint256) {
    (uint256 _lpTokenAmount, uint256 balanceBefore) =
      _removeLiquidityOneCoinBefore(curvePool, lpToken, tokenI, lpTokenAmount);
    ICurvePool(curvePool).remove_liquidity_one_coin(lpToken, _lpTokenAmount, i, minAmount);

    return _removeLiquidityOneCoinAfter(curvePool, lpToken, tokenI, balanceBefore);
  }

  function stake(address gaugeAddress, uint256 _value) external {
    ICurveGauge gauge = ICurveGauge(gaugeAddress);
    address token = gauge.lp_token();

    SafeTransferLib.safeApprove(ERC20(token), gaugeAddress, _value);
    bytes memory data = abi.encodeWithSelector(gauge.deposit.selector, _value, msg.sender);
    ///@notice we need to call via delegatecall, because gauge tokens can't be transfered to router
    data.exec(gaugeAddress, type(uint256).max);
  }

  function unstake(address gaugeAddress, uint256 _value) external returns (uint256) {
    ICurveGauge gauge = ICurveGauge(gaugeAddress);

    bytes memory data = abi.encodeWithSelector(gauge.withdraw.selector, _value);
    ///@notice we need to call via delegatecall, because gauge tokens can't be transfered to router
    data.exec(gaugeAddress, type(uint256).max);
    return _value;
  }

  function _addLiquidityBefore(address curvePool, address lpToken, address[] memory tokens, uint256[] memory amounts)
    internal
    returns (uint256[] memory, uint256, uint256)
  {
    uint256 balanceBefore = IERC20(lpToken).balanceOf(address(this));

    // Approve non-zero amount erc20 token and set eth amount
    uint256 ethAmount;
    for (uint256 i = 0; i < amounts.length; i++) {
      if (amounts[i] == 0) continue;
      amounts[i] = balanceOf(tokens[i], amounts[i]);
      if (tokens[i] == Constants.NATIVE_TOKEN) {
        ethAmount = amounts[i];
        continue;
      }
      SafeTransferLib.safeApprove(ERC20(tokens[i]), curvePool, amounts[i]);
    }

    return (amounts, balanceBefore, ethAmount);
  }

  function _addLiquidityAfter(
    address curvePool,
    address lpToken,
    address[] memory tokens,
    uint256[] memory amounts,
    uint256 balanceBefore
  ) internal returns (uint256) {
    uint256 balance = IERC20(lpToken).balanceOf(address(this));
    require(balance > balanceBefore, "Error: after <= before");

    for (uint256 i = 0; i < amounts.length; i++) {
      if (amounts[i] == 0) continue;
      if (tokens[i] != Constants.NATIVE_TOKEN) {
        SafeTransferLib.safeApprove(ERC20(tokens[i]), curvePool, 0);
        _sweepToken(tokens[i]);
      }
    }

    _sweepToken(lpToken);

    return balance - balanceBefore;
  }

  function _removeLiquidityOneCoinBefore(address curvePool, address lpToken, address tokenI, uint256 lpTokenAmount)
    internal
    returns (uint256, uint256)
  {
    uint256 balanceBefore = balanceOf(tokenI, 0);
    lpTokenAmount = balanceOf(lpToken, lpTokenAmount);
    SafeTransferLib.safeApprove(ERC20(lpToken), curvePool, lpTokenAmount);

    return (lpTokenAmount, balanceBefore);
  }

  function _removeLiquidityOneCoinAfter(address curvePool, address lpToken, address tokenI, uint256 balanceBefore)
    internal
    returns (uint256)
  {
    // Some curve non-underlying lpTokens like 3lpToken won't consume lpToken token
    // allowance since lpToken token was issued by the lpToken that don't need to
    // call transferFrom(). So set approval to 0 here.
    SafeTransferLib.safeApprove(ERC20(lpToken), curvePool, 0);
    uint256 balance = balanceOf(tokenI, 0);
    require(balance > balanceBefore, "Error: after <= before");

    _sweepToken(tokenI);

    return balance - balanceBefore;
  }
}
