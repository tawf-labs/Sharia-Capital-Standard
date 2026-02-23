// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {MudarabahPool} from "./MudarabahPool.sol";
import {ISCS4} from "../interfaces/ISCS4.sol";

/// @title MudarabahFactory
/// @notice Factory for creating AAOIFI-compliant Mudarabah pools
contract MudarabahFactory {
    ISCS4 public immutable enforcement;
    address[] public pools;
    mapping(address => bool) public isPool;

    event PoolCreated(address indexed pool, address indexed manager, address indexed capitalProvider);

    error InvalidParameters();

    constructor(address _enforcement) {
        enforcement = ISCS4(_enforcement);
    }

    function createPool(
        address asset,
        address manager,
        address capitalProvider,
        uint256 managerShareBps,
        uint256 providerShareBps,
        string memory name,
        string memory symbol
    ) external returns (address pool) {
        if (manager == address(0) || capitalProvider == address(0) || asset == address(0)) {
            revert InvalidParameters();
        }

        enforcement.validateProfitRatio(managerShareBps, providerShareBps);

        pool = address(new MudarabahPool(
            asset,
            manager,
            capitalProvider,
            managerShareBps,
            providerShareBps,
            address(enforcement),
            name,
            symbol
        ));

        pools.push(pool);
        isPool[pool] = true;

        emit PoolCreated(pool, manager, capitalProvider);
    }

    function getPoolCount() external view returns (uint256) {
        return pools.length;
    }

    function getPool(uint256 index) external view returns (address) {
        return pools[index];
    }
}
