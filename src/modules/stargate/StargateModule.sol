// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import "./IStargateFactory.sol";
import "./IStargateRouter.sol";
import "./IStargatePool.sol";
import "./IStargateLPStaking.sol";
import "../../utils/Constants.sol";
import "../../utils/LibCalldata.sol";
import "../ModuleBase.sol";

contract StargateModule is ModuleBase {
  using LibCalldata for bytes;

  struct StakePool {
    bool exists;
    uint16 stakingId;
  }

  IStargateFactory public immutable factory;
  IStargateRouter public immutable router;
  IStargateLPStaking public immutable staking;

  mapping(address => address) internal tokenToPool;
  mapping(address => StakePool) internal poolToStakingId;

  ///@notice Stargate module uses custom wrapper for ETH, called SGETH
  constructor(address factory_, address router_, address lpStaking, address sgeth) ModuleBase(sgeth) {
    factory = IStargateFactory(factory_);
    router = IStargateRouter(router_);
    staking = IStargateLPStaking(lpStaking);
    cachePoolIds();
  }

  function cachePoolIds() public {
    uint256 poolsCount = factory.allPoolsLength();
    for (uint256 poolId = 0; poolId < poolsCount; poolId++) {
      IStargatePool pool = factory.getPool(poolId);
      tokenToPool[pool.token()] = address(pool);
    }

    uint256 stakePoolsCount = staking.poolLength();
    for (uint256 stakingId = 0; stakingId < stakePoolsCount; stakingId++) {
      address pool = address(staking.poolInfo(stakingId).lpToken);
      poolToStakingId[pool] = StakePool({ stakingId: uint16(stakingId), exists: true });
    }
  }

  function getPool(address token) public view returns (IStargatePool) {
    address poolAddr = tokenToPool[token];
    require(poolAddr != address(0), "Error: pool doesn't exists");
    return IStargatePool(poolAddr);
  }

  function addLiquidity(address token, uint256 amount) public payable returns (uint256 ret) {
    if (token == Constants.NATIVE_TOKEN && amount == msg.value) {
      amount = wrapETH(amount);
      token = address(WETH9);
    }

    IStargatePool pool = getPool(token);

    uint256 balanceBefore = balanceOf(address(pool), 0);

    router.addLiquidity(pool.poolId(), amount, address(this));

    ret = balanceOf(address(pool), 0) - balanceBefore;
  }

  function removeLiquidity(address token, uint256 amount) public payable returns (uint256 ret) {
    bool useNative = token == Constants.NATIVE_TOKEN && amount == msg.value;
    if (useNative) {
      token = address(WETH9);
    }
    uint16 poolId = uint16(getPool(token).poolId());
    uint256 lpAmount = LDtoLP(token, amount);
    ret = router.instantRedeemLocal(poolId, lpAmount, address(this));

    if (useNative) {
      unwrapWETH9(amount);
    }
  }

  function stake(address token, uint256 amount) public payable {
    address poolAddr = address(getPool(token));
    require(poolToStakingId[poolAddr].exists, "Error: staking pool doesn't exists");
    
    uint256 stakingId = uint256(poolToStakingId[poolAddr].stakingId);

    bytes memory data = abi.encodeWithSelector(staking.deposit.selector, stakingId, amount);
    data.exec(address(staking), type(uint256).max);
  }

  function unstake(address token, uint256 amount) public payable {
    address poolAddr = address(getPool(token));
    require(poolToStakingId[poolAddr].exists, "Error: staking pool doesn't exists");

    uint256 stakingId = uint256(poolToStakingId[poolAddr].stakingId);

    bytes memory data = abi.encodeWithSelector(staking.withdraw.selector, stakingId, amount);
    data.exec(address(staking), type(uint256).max);
  }

  function LDtoLP(address token, uint256 amount) internal view returns (uint256) {
    IStargatePool pool = getPool(token);
    uint256 convertRate = pool.convertRate();
    uint256 totalSupply = pool.convertRate();
    uint256 totalLiquidity = pool.convertRate();

    return (amount / convertRate) * totalSupply / totalLiquidity;
  }
}
