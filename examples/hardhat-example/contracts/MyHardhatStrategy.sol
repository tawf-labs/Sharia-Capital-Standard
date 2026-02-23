// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Clean import style
import "@sharia-capital/standard/SCS1/MudarabahPool.sol";
import "@sharia-capital/standard/SCS4/SCSEnforcement.sol";

// Alternative: Direct path import
// import "@sharia-capital/standard/evm/src/SCS1/MudarabahPool.sol";

contract MyHardhatStrategy {
    MudarabahPool public pool;
    SCSEnforcement public enforcement;

    constructor(address _pool, address _enforcement) {
        pool = MudarabahPool(_pool);
        enforcement = SCSEnforcement(_enforcement);
    }

    function getPoolInfo() external view returns (uint256 totalAssets, uint256 managerShare) {
        totalAssets = pool.totalAssets();
        (managerShare,) = pool.profitShares();
    }
}
