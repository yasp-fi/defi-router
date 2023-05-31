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

contract StargateRegistry {
  struct StakePool {
    bool exists;
    uint16 stakingId;
  }

  IStargateLPStaking public immutable staking;
  IStargateFactory public immutable factory;

  mapping(address => address) internal tokenToPool;
  mapping(address => StakePool) internal poolToStakingId;

  constructor(address factory_, address staking_) {
    factory = IStargateFactory(factory_);
    staking = IStargateLPStaking(staking_);
    cachePoolIds();
  }

  function getPool(address token) public view returns (IStargatePool) {
    address poolAddr = tokenToPool[token];
    require(poolAddr != address(0), "Error: pool doesn't exists");
    return IStargatePool(poolAddr);
  }

  function getStakingId(address pool) public view returns (uint256) {
    require(poolToStakingId[pool].exists, "Error: staking pool doesn't exists");
    return uint256(poolToStakingId[pool].stakingId);
  }

  function cachePoolIds() public {
    uint256 poolsCount = factory.allPoolsLength();
    for (uint256 poolId = 0; poolId < poolsCount; poolId++) {
      address poolAddr = factory.allPools(poolId);
      IStargatePool pool = IStargatePool(poolAddr);
      tokenToPool[pool.token()] = poolAddr;
    }

    uint256 stakePoolsCount = staking.poolLength();
    for (uint256 stakingId = 0; stakingId < stakePoolsCount; stakingId++) {
      address pool = address(staking.poolInfo(stakingId).lpToken);
      poolToStakingId[pool] = StakePool({ stakingId: uint16(stakingId), exists: true });
    }
  }
}