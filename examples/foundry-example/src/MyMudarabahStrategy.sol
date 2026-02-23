// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@sharia-capital/SCS1/MudarabahPool.sol";
import "@sharia-capital/SCS4/SCSEnforcement.sol";

contract MyMudarabahStrategy {
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
