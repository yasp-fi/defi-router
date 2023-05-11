// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC4626.sol";
import "./IStargateRouter.sol";
import "./IStargateLPStaking.sol";

abstract contract StargateModule {
    function stargateProvideLiquidity(address router, uint256 poolId, uint256 assets) public {
        IStargateRouter(router).addLiquidity(poolId, assets, address(this));
    }

    function stargateRemoveLiquidity(address router, uint16 poolId, uint256 assets) public {
        IStargateRouter(router).instantRedeemLocal(poolId, assets, address(this));
    }

    function stargateStake(address stakingVault, uint256 assets) public {
        IERC4626(stakingVault).deposit(assets, address(this));
    }

    function stargateUnstake(address stakingVault, uint256 assets) public {
        IERC4626(stakingVault).withdraw(assets, address(this), address(this));
    }

    function stargateCollectRewards(address staking, address user) public {
        // TODO: add ERC4626-based staking collect reward
    }
}
