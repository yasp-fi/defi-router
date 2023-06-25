// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStargateRouter {
  function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to)
    external;

  function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to)
    external
    returns (uint256);
}

interface IStargatePool {
  function poolId() external view returns (uint256);
  function token() external view returns (address);
  function totalSupply() external view returns (uint256);
  function totalLiquidity() external view returns (uint256);
  function convertRate() external view returns (uint256);
  function amountLPtoLD(uint256 _amountLP) external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function approve(address recipient, uint256 amount) external;
}
