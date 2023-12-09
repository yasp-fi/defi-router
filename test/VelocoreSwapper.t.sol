// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/interfaces/IERC20.sol";
import "forge-std/Test.sol";
import "./mocks/ERC20.m.sol";
import "../src/helpers/VelocoreSwapper.sol";

contract VelocoreSwapperTest is Test {
  address public OWNER = address(0xdEADBEeF00000000000000000000000000000000);
  address public TREASURY = address(0xdEADBEeF00000000000000000000000000000000);

  address public VAULT = address(0x1d0188c4B276A09366D05d6Be06aF61a73bC7535);
  address public WETH = address(0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f);
  address public USDC = address(0x176211869cA2b568f2A7D4EE941E073a821EE1ff);
  address public BUSD = address(0x7d43AABC515C356145049227CeE54B608342c0ad);
  address public constant NATIVE_TOKEN_ADDRESS =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  uint256 constant MAX_BPS = 10000;

  uint8 constant EXACTLY = 0;
  uint8 constant AT_MOST = 1;
  uint8 constant ALL = 2;

  VelocoreSwapper public swapper;
  address public somebody = address(0xdadada);

  modifier withActor(uint256 seed, uint64 ethValue) {
    vm.assume(
      seed
        <
        115792089237316195423570985008687907852837564279074904382605163141518161494337
    );
    vm.assume(seed > 0);
    vm.assume(ethValue > 1e8);
    address actor = vm.addr(seed);

    vm.label(actor, "Actor");
    vm.startPrank(actor);
    _;
    vm.stopPrank();
  }

  function toPoolId(uint8 _optype, address _pool) public pure returns (bytes32) {
    return bytes32(bytes1(_optype)) | bytes32(uint256(uint160(address(_pool))));
  }

  function toToken(address tok) public pure returns (bytes32) {
    return bytes32(uint256(uint160(tok)));
  }

  function toTokenInfo(bytes1 _tokenRefIndex, uint8 _method, int128 _amount)
    public
    pure
    returns (bytes32)
  {
    return bytes32(bytes1(_tokenRefIndex)) | bytes32(bytes2(uint16(_method)))
      | bytes32(uint256(uint128(uint256(int256(_amount)))));
  }

  function setUp() public {
    swapper = new VelocoreSwapper(OWNER, TREASURY, VAULT, 75);
    vm.label(address(swapper), "VelocoreSwapper");
  }

  function test_admin_setTreasury() public {
    vm.startPrank(OWNER);
    swapper.admin_setTreasury(TREASURY);
    vm.stopPrank();
  }

  function test_admin_setVault() public {
    vm.startPrank(OWNER);
    swapper.admin_setVault(VAULT);
    vm.stopPrank();
  }

  function test_admin_setFees() public {
    vm.startPrank(OWNER);
    swapper.admin_setSwapFee(50);
    vm.stopPrank();
  }

  function test_admin_sweep() public {
    vm.deal(address(swapper), 1000);
    vm.startPrank(OWNER);
    swapper.admin_sweep(NATIVE_TOKEN_ADDRESS, TREASURY);
    swapper.admin_sweep(BUSD, TREASURY);
    vm.stopPrank();
  }

  function testFail_admin_setTreasury() public {
    vm.startPrank(somebody);
    swapper.admin_setTreasury(TREASURY);
    vm.stopPrank();
  }

  function testFail_admin_setVault() public {
    vm.startPrank(somebody);
    swapper.admin_setVault(VAULT);
    vm.stopPrank();
  }

  function testFail_admin_setFees() public {
    vm.startPrank(somebody);
    swapper.admin_setSwapFee(0);
    vm.stopPrank();
  }

  function testFail_admin_setFeesMax() public {
    vm.startPrank(OWNER);
    swapper.admin_setSwapFee(type(uint16).max);
    vm.stopPrank();
  }

  function testFail_admin_sweep() public {
    vm.deal(address(swapper), 1000);
    vm.startPrank(somebody);
    swapper.admin_sweep(NATIVE_TOKEN_ADDRESS, somebody);
    vm.stopPrank();
  }

  function test_execute_native_erc_swap(uint256 seed, uint64 ethValue)
    public
    withActor(seed, ethValue)
  {
    address actor = vm.addr(seed);
    vm.deal(actor, uint256(ethValue));

    (uint256 feeAmount, uint256 restAmount) = swapper.calcFees(ethValue);
    address usdcEthPool = address(0xe2c67A9B15e9E7FF8A9Cb0dFb8feE5609923E5DB);

    bytes32[] memory tokenRef = new bytes32[](2);
    tokenRef[0] = bytes32(
      0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
    );
    tokenRef[1] = toToken(USDC);

    VelocoreOperation[] memory ops = new VelocoreOperation[](1);
    ops[0].poolId = toPoolId(0, usdcEthPool);
    ops[0].tokenInformations = new bytes32[](2);
    ops[0].tokenInformations[0] =
      toTokenInfo(0x00, EXACTLY, int128(uint128(restAmount)));
    ops[0].tokenInformations[1] = toTokenInfo(0x01, AT_MOST, 0);
    ops[0].data = "";

    uint256 amountOut = swapper.execute{ value: ethValue }(
      tokenRef, new int128[](2), ops, ethValue, NATIVE_TOKEN_ADDRESS, USDC
    );

    assertEq(IERC20(USDC).balanceOf(actor), amountOut);
    assertEq(TREASURY.balance, feeAmount);
  }

  function test_execute_erc_native_swap(uint256 seed, uint64 ethValue)
    public
    withActor(seed, ethValue)
  {
    address actor = vm.addr(seed);
    deal(USDC, actor, uint256(ethValue));

    (uint256 feeAmount, uint256 restAmount) = swapper.calcFees(ethValue);
    address usdcEthPool = address(0xe2c67A9B15e9E7FF8A9Cb0dFb8feE5609923E5DB);

    bytes32[] memory tokenRef = new bytes32[](2);
    tokenRef[0] = toToken(USDC);
    tokenRef[1] = bytes32(
      0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
    );

    VelocoreOperation[] memory ops = new VelocoreOperation[](1);
    ops[0].poolId = toPoolId(0, usdcEthPool);
    ops[0].tokenInformations = new bytes32[](2);
    ops[0].tokenInformations[0] =
      toTokenInfo(0x00, EXACTLY, int128(uint128(restAmount)));
    ops[0].tokenInformations[1] = toTokenInfo(0x01, AT_MOST, 0);
    ops[0].data = "";

    IERC20(USDC).approve(address(swapper), ethValue);
    uint256 amountOut = swapper.execute(
      tokenRef, new int128[](2), ops, ethValue, USDC, NATIVE_TOKEN_ADDRESS
    );

    assertEq(actor.balance, amountOut);
    assertEq(IERC20(USDC).balanceOf(TREASURY), feeAmount);
  }

  function test_execute_erc_erc_swap(uint256 seed, uint64 ethValue)
    public
    withActor(seed, ethValue)
  {
    address actor = vm.addr(seed);
    deal(BUSD, actor, ethValue, true);

    (uint256 feeAmount, uint256 restAmount) = swapper.calcFees(ethValue);
    address usdcBusdPool = address(0xbF820C71b9dfE09743cC8134Ab3b224D6Bc333C7);

    bytes32[] memory tokenRef = new bytes32[](2);
    tokenRef[0] = toToken(BUSD);
    tokenRef[1] = toToken(USDC);

    VelocoreOperation[] memory ops = new VelocoreOperation[](1);
    ops[0].poolId = toPoolId(0, usdcBusdPool);
    ops[0].tokenInformations = new bytes32[](2);
    ops[0].tokenInformations[0] =
      toTokenInfo(0x00, EXACTLY, int128(uint128(restAmount)));
    ops[0].tokenInformations[1] = toTokenInfo(0x01, AT_MOST, 0);
    ops[0].data = "";

    IERC20(BUSD).approve(address(swapper), ethValue);
    uint256 amountOut =
      swapper.execute(tokenRef, new int128[](2), ops, ethValue, BUSD, USDC);

    assertEq(IERC20(USDC).balanceOf(actor), amountOut);
    assertEq(IERC20(BUSD).balanceOf(TREASURY), feeAmount);
  }

  function test_execute_erc_swap_zero_fees(uint256 seed, uint64 ethValue)
    public
  {
    vm.startPrank(OWNER);
    swapper.admin_setSwapFee(0);
    vm.stopPrank();
    vm.assume(
      seed
        <
        115792089237316195423570985008687907852837564279074904382605163141518161494337
    );
    vm.assume(seed > 0);
    vm.assume(ethValue > 1e18);
    address actor = vm.addr(seed);

    vm.label(actor, "Actor");
    vm.startPrank(actor);
    deal(BUSD, actor, ethValue, true);

    (uint256 feeAmount, uint256 restAmount) = swapper.calcFees(ethValue);
    address usdcBusdPool = address(0xbF820C71b9dfE09743cC8134Ab3b224D6Bc333C7);

    bytes32[] memory tokenRef = new bytes32[](2);
    tokenRef[0] = toToken(BUSD);
    tokenRef[1] = toToken(USDC);

    VelocoreOperation[] memory ops = new VelocoreOperation[](1);
    ops[0].poolId = toPoolId(0, usdcBusdPool);
    ops[0].tokenInformations = new bytes32[](2);
    ops[0].tokenInformations[0] =
      toTokenInfo(0x00, EXACTLY, int128(uint128(restAmount)));
    ops[0].tokenInformations[1] = toTokenInfo(0x01, AT_MOST, 0);
    ops[0].data = "";

    IERC20(BUSD).approve(address(swapper), ethValue);
    uint256 amountOut =
      swapper.execute(tokenRef, new int128[](2), ops, ethValue, BUSD, USDC);

    assertEq(IERC20(USDC).balanceOf(actor), amountOut);
    assertEq(IERC20(BUSD).balanceOf(TREASURY), feeAmount);
    vm.stopPrank();
  }

  function testFail_execute_erc_swap_amountIn_overflow(
    uint256 seed,
    uint64 ethValue
  ) public withActor(seed, ethValue) {
    address actor = vm.addr(seed);
    deal(BUSD, actor, ethValue, true);
    deal(BUSD, address(swapper), ethValue, true);

    address usdcBusdPool = address(0xbF820C71b9dfE09743cC8134Ab3b224D6Bc333C7);

    bytes32[] memory tokenRef = new bytes32[](2);
    tokenRef[0] = toToken(BUSD);
    tokenRef[1] = toToken(USDC);

    VelocoreOperation[] memory ops = new VelocoreOperation[](1);
    ops[0].poolId = toPoolId(0, usdcBusdPool);
    ops[0].tokenInformations = new bytes32[](2);
    ops[0].tokenInformations[0] =
      toTokenInfo(0x00, EXACTLY, int128(uint128(ethValue)));
    ops[0].tokenInformations[1] = toTokenInfo(0x01, AT_MOST, 0);
    ops[0].data = "";

    IERC20(BUSD).approve(address(swapper), ethValue);

    swapper.execute(tokenRef, new int128[](2), ops, ethValue, BUSD, USDC);
  }

  function testFail_execute_erc_swap_amountIn_underlflow(
    uint256 seed,
    uint64 ethValue
  ) public withActor(seed, ethValue) {
    address actor = vm.addr(seed);
    deal(BUSD, actor, ethValue, true);
    deal(BUSD, address(swapper), ethValue, true);

    address usdcBusdPool = address(0xbF820C71b9dfE09743cC8134Ab3b224D6Bc333C7);
    (, uint256 restAmount) = swapper.calcFees(ethValue);

    bytes32[] memory tokenRef = new bytes32[](2);
    tokenRef[0] = toToken(BUSD);
    tokenRef[1] = toToken(USDC);

    VelocoreOperation[] memory ops = new VelocoreOperation[](1);
    ops[0].poolId = toPoolId(0, usdcBusdPool);
    ops[0].tokenInformations = new bytes32[](2);
    ops[0].tokenInformations[0] =
      toTokenInfo(0x00, EXACTLY, int128(uint128(ethValue)));
    ops[0].tokenInformations[1] = toTokenInfo(0x01, AT_MOST, 0);
    ops[0].data = "";

    IERC20(BUSD).approve(address(swapper), restAmount);

    swapper.execute(tokenRef, new int128[](2), ops, restAmount, BUSD, USDC);
  }
}
