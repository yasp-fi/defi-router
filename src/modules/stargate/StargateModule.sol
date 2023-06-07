// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import "./IStargateRouter.sol";
import "./IStargatePool.sol";
import "./StargateRegistry.sol";
import "../../utils/Constants.sol";
import "../../utils/LibCalldata.sol";
import "../ModuleBase.sol";

contract StargateModule is ModuleBase {
  using LibCalldata for bytes;

  IStargateRouter public immutable router;
  StargateRegistry public immutable registry;

  ///@notice Stargate module uses custom wrapper for ETH, called SGETH
  constructor(address registry_, address router_, address sgeth_) ModuleBase(sgeth_) {
    router = IStargateRouter(router_);
    registry = StargateRegistry(registry_);
  }

  function getPosition(address token) public view returns (address lpToken, address stakingPool) {
    address poolToken = token == Constants.NATIVE_TOKEN ? address(WETH9) : token;
    lpToken = address(registry.getPool(poolToken));
    stakingPool = address(registry.staking());
  }

  function positionOf(address user, address token) public view returns (uint256 amount, uint256 amountDeposited) {
    address poolToken = token == Constants.NATIVE_TOKEN ? address(WETH9) : token;
    IStargatePool pool = registry.getPool(poolToken);

    amount = balanceOf(token, user);
    amountDeposited = balanceOf(address(pool), user);
    amountDeposited = pool.amountLPtoLD(amountDeposited);
  }

  function positionOf(address user, address token, address)
    public
    view
    returns (uint256 amount, uint256 amountDeposited, uint256 amountStaked, uint256 pendingRewards)
  {
    (amount, amountDeposited) = positionOf(user, token);

    address poolToken = token == Constants.NATIVE_TOKEN ? address(WETH9) : token;
    IStargatePool pool = registry.getPool(poolToken);
    uint256 stakingId = registry.getStakingId(address(pool));

    amountStaked = registry.staking().userInfo(stakingId, user).amount;
    amountStaked = pool.amountLPtoLD(amountStaked);
    pendingRewards = registry.staking().pendingStargate(stakingId, user);
  }

  function deposit(address token, uint256 amount) public payable returns (uint256) {
    bool useNative = token == Constants.NATIVE_TOKEN;
    amount = useNative ? wrapETH(amount) : amount;
    token = useNative ? address(WETH9) : token;

    IERC20(token).approve(address(router), amount);
    IStargatePool pool = registry.getPool(token);

    uint256 balanceBefore = balanceOf(address(pool), type(uint256).max);
    router.addLiquidity(pool.poolId(), amount, address(this));

    _sweepToken(address(pool));

    return balanceOf(address(pool), type(uint256).max) - balanceBefore;
  }

  function withdraw(address token, uint256 amount) public payable returns (uint256) {
    bool useNative = token == Constants.NATIVE_TOKEN;
    token = useNative ? address(WETH9) : token;

    uint16 poolId = uint16(registry.getPool(token).poolId());
    uint256 lpAmount = LDtoLP(token, amount);

    uint256 balanceBefore = balanceOf(token, type(uint256).max);
    router.instantRedeemLocal(poolId, lpAmount, address(this));

    _sweepToken(token);

    return balanceOf(token, type(uint256).max) - balanceBefore;
  }

  function stakeExternal(address token, uint256 amount) public view returns (address target, bytes memory data) {
    token = token == Constants.NATIVE_TOKEN ? address(WETH9) : token;
    amount = balanceOf(token, amount, msg.sender);

    IStargatePool pool = registry.getPool(token);
    uint256 stakingId = registry.getStakingId(address(pool));

    target = address(registry.staking());
    data = abi.encodeWithSelector(IStargateLPStaking.deposit.selector, stakingId, LDtoLP(token, amount));
  }

  function unstakeExternal(address token, uint256 amount) public view returns (address target, bytes memory data) {
    token = token == Constants.NATIVE_TOKEN ? address(WETH9) : token;

    IStargatePool pool = registry.getPool(token);
    uint256 stakingId = registry.getStakingId(address(pool));

    target = address(registry.staking());
    data = abi.encodeWithSelector(IStargateLPStaking.withdraw.selector, stakingId, LDtoLP(token, amount));
  }

  function collectRewardsExternal(address token) public view returns (address target, bytes memory data) {
    token = token == Constants.NATIVE_TOKEN ? address(WETH9) : token;

    IStargatePool pool = registry.getPool(token);
    uint256 stakingId = registry.getStakingId(address(pool));

    target = address(registry.staking());
    data = abi.encodeWithSelector(IStargateLPStaking.withdraw.selector, stakingId, 0);
  }

  function LDtoLP(address token, uint256 amount) internal view returns (uint256) {
    IStargatePool pool = registry.getPool(token);
    uint256 convertRate = pool.convertRate();
    uint256 totalSupply = pool.totalSupply();
    uint256 totalLiquidity = pool.totalLiquidity();

    return (amount / convertRate) * totalSupply / totalLiquidity;
  }
}
