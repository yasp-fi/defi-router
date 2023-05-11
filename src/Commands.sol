// pragma solidity ^0.8.13;

// library Commands {
//   // Masks to extract certain bits of commands
//   bytes1 internal constant FLAG_ALLOW_REVERT = 0x80;
//   bytes1 internal constant COMMAND_TYPE_MASK = 0x3f;

//   // Commands

//   uint256 constant SWEEP = 0x00;
//   uint256 constant TRANSFER = 0x01;
//   uint256 constant WRAP_ETH = 0x02;
//   uint256 constant UNWRAP_ETH = 0x03;
//   uint256 constant APPROVE_ERC20 = 0x04;
//   // uint256 constant UNKNOWN = 0x05;
//   // uint256 constant UNKNOWN = 0x06;
//   // uint256 constant UNKNOWN = 0x07;
//   // uint256 constant UNKNOWN = 0x08;
//   // uint256 constant UNKNOWN = 0x09;
//   // uint256 constant UNKNOWN = 0x0a;
//   // uint256 constant UNKNOWN = 0x0b;
//   // uint256 constant UNKNOWN = 0x0c;
//   // uint256 constant UNKNOWN = 0x0d;
//   // uint256 constant UNKNOWN = 0x0e;
//   // uint256 constant UNKNOWN = 0x0f;

//   uint256 constant FIRST_IF_BOUNDARY = 0x10;

//   uint256 constant PERMIT2_PERMIT = 0x10;
//   uint256 constant PERMIT2_TRANSFER_FROM = 0x11;
//   uint256 constant PERMIT2_PERMIT_BATCH = 0x12;
//   uint256 constant PERMIT2_TRANSFER_FROM_BATCH = 0x13;
//   uint256 constant PAY_PORTION = 0x14;
//   uint256 constant UNISWAPV3_EXACT_IN = 0x15;
//   uint256 constant UNISWAPV3_EXACT_OUT = 0x16;
//   uint256 constant CURVE_SWAP = 0x17;
//   uint256 constant BALANCER_SWAP = 0x18;
//   // uint256 constant UNISWAPV2_EXACT_IN = 0x19;
//   // uint256 constant UNISWAPV2_EXACT_OUT = 0x1a;
//   uint256 constant ERC4626_DEPOSIT = 0x1b;
//   uint256 constant ERC4626_WITHDRAW = 0x1c;
//   uint256 constant ERC4626_MINT = 0x1d;
//   uint256 constant ERC4626_REDEEM = 0x1e;
//   // uint256 constant UNKNOWN = 0x1f;

//   uint256 constant SECOND_IF_BOUNDARY = 0x20;

//   uint256 constant AAVE_PROVIDE_LIQUIDITY = 0x20;
//   uint256 constant AAVE_REMOVE_LIQUIDITY = 0x21;
//   uint256 constant AAVE_COLLECT_REWARDS = 0x22;
//   uint256 constant COMPOUND_PROVIDE_LIQUIDITY = 0x23;
//   uint256 constant COMPOUND_REMOVE_LIQUIDITY = 0x24;
//   uint256 constant COMPOUND_COLLECT_REWARDS = 0x25;
//   uint256 constant CURVE_PROVIDE_LIQUIDITY = 0x26;
//   uint256 constant CURVE_REMOVE_LIQUIDITY = 0x27;
//   uint256 constant CURVE_STAKE = 0x28;
//   uint256 constant CURVE_UNSTAKE = 0x29;
//   uint256 constant CURVE_COLLECT_REWARDS = 0x2a;
//   uint256 constant BALANCER_PROVIDER_LIQUIDITY = 0x2b;
//   uint256 constant BALANCER_REMOVE_LIQUIDITY = 0x2c;
//   uint256 constant BALANCER_STAKE = 0x2d;
//   uint256 constant BALANCER_UNSTAKE = 0x2e;
//   uint256 constant BALANCER_COLLECT_REWARDS = 0x2f;

//   uint256 constant THIRD_IF_BOUNDARY = 0x30;

//   uint256 constant BALANCE_CHECK_ERC20 = 0x30;
//   uint256 constant OWNER_CHECK_721 = 0x31;
//   uint256 constant OWNER_CHECK_1155 = 0x32;
//   uint256 constant SWEEP_ERC721 = 0x33;
//   uint256 constant SWEEP_ERC1155 = 0x34;
//   // uint256 constant UNKNOWN = 0x35;
//   // uint256 constant UNKNOWN = 0x36;
//   // uint256 constant UNKNOWN = 0x37;
//   // uint256 constant UNKNOWN = 0x38;
//   // uint256 constant UNKNOWN = 0x39;
//   // uint256 constant UNKNOWN = 0x3a;
//   // uint256 constant UNKNOWN = 0x3b;
//   // uint256 constant UNKNOWN = 0x3c;
//   // uint256 constant UNKNOWN = 0x3d;
//   // uint256 constant UNKNOWN = 0x3e;
//   // uint256 constant UNKNOWN = 0x3f;
// }
