// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/interfaces/IERC20.sol";
import "../utils/Owned.sol";

struct VelocoreOperation {
  bytes32 poolId;
  bytes32[] tokenInformations;
  bytes data;
}

interface IVault {
  function getPair(address fromAddress, address toAddress)
    external
    view
    returns (address);

  function execute(
    bytes32[] calldata tokenRef,
    int128[] memory deposit,
    VelocoreOperation[] calldata ops
  ) external payable;

  function query(
    address user,
    bytes32[] calldata tokenRef,
    int128[] memory deposit,
    VelocoreOperation[] calldata ops
  ) external returns (int128[] memory);
}

contract VelocoreSwapper is Owned {
  address public constant NATIVE_TOKEN_ADDRESS =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  uint256 constant MAX_BPS = 10000;

  address public treasury;
  address public vault;
  uint256 public swapFeeBps;

  event FeeCollected(
    address indexed payer, address indexed token, uint256 amount
  );

  event Swap(
    address indexed payer,
    address indexed fromToken,
    address indexed toToken,
    uint256 amountIn,
    uint256 amountOut,
    uint256 feesPaid
  );

  constructor(address owner_, address treasury_, address vault_, uint16 feeBps)
    Owned(owner_)
  {
    require(feeBps <= MAX_BPS, "BPS > 10000");
    treasury = treasury_;
    vault = vault_;
    swapFeeBps = feeBps;
  }

  //// Admin Functions

  function admin_setTreasury(address newTreasury_) public onlyOwner {
    treasury = newTreasury_;
  }

  function admin_setVault(address newVault_) public onlyOwner {
    vault = newVault_;
  }

  function admin_setSwapFee(uint16 feeBps) public onlyOwner {
    require(feeBps <= MAX_BPS, "BPS > 10000");
    swapFeeBps = feeBps;
  }

  function admin_sweep(address token, address receiver)
    external
    onlyOwner
    returns (uint256 amountSweeped)
  {
    amountSweeped = getBalance(token);
    _transferFrom(token, address(this), receiver, amountSweeped);
  }

  /// Views

  function getBalance(address token) public view returns (uint256 balance) {
    if (token == NATIVE_TOKEN_ADDRESS) {
      balance = address(this).balance;
    } else {
      balance = IERC20(token).balanceOf(address(this));
    }
  }

  function calcFees(uint256 amountIn)
    public
    view
    returns (uint256 feeAmount, uint256 restAmount)
  {
    feeAmount = amountIn * swapFeeBps / MAX_BPS;
    restAmount = amountIn - feeAmount;
  }

  /// External Functions

  function execute(
    bytes32[] calldata tokenRef,
    int128[] memory deposit,
    VelocoreOperation[] memory ops,
    uint256 amountIn,
    address tokenIn,
    address tokenOut
  ) public payable returns (uint256 amountOut) {
    uint256 balanceBefore = getBalance(tokenOut);

    (uint256 feePaid, uint256 restAmount) =
      _applyFees(msg.sender, tokenIn, amountIn);

    _transferFrom(tokenIn, msg.sender, address(this), restAmount);

    _approve(tokenIn, vault, restAmount);
    IVault(vault).execute{
      value: tokenIn == NATIVE_TOKEN_ADDRESS ? restAmount : 0
    }(tokenRef, deposit, ops);

    amountOut = getBalance(tokenOut) - balanceBefore;

    _transferFrom(tokenOut, address(this), msg.sender, amountOut);

    emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut, feePaid);
  }

  /// Internal Functions

  function _applyFees(address payer, address token, uint256 amount)
    internal
    returns (uint256 feeAmount, uint256 restAmount)
  {
    require(amount > 0, "Zero amount");

    if (swapFeeBps == 0) {
      return (0, amount);
    }

    (feeAmount, restAmount) = calcFees(amount);
    _transferFrom(token, payer, treasury, feeAmount);

    emit FeeCollected(payer, token, feeAmount);
  }

  function _transferFrom(
    address token,
    address fromAddress,
    address toAddress,
    uint256 amount
  ) internal {
    if (token == NATIVE_TOKEN_ADDRESS && toAddress != address(this)) {
      payable(toAddress).transfer(amount);
    }

    if (token != NATIVE_TOKEN_ADDRESS && fromAddress != address(this)) {
      IERC20(token).transferFrom(fromAddress, toAddress, amount);
    }

    if (token != NATIVE_TOKEN_ADDRESS && fromAddress == address(this)) {
      IERC20(token).transfer(toAddress, amount);
    }
  }

  function _approve(address token, address toAddress, uint256 amount) internal {
    if (token != NATIVE_TOKEN_ADDRESS) {
      IERC20(token).approve(toAddress, amount);
    }
  }

  receive() external payable { }
}
