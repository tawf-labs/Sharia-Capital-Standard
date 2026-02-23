// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {MusharakahPool} from "./MusharakahPool.sol";
import {ISCS4} from "../interfaces/ISCS4.sol";

/// @title MusharakahFactory
/// @notice Factory for creating AAOIFI-compliant Musharakah pools
contract MusharakahFactory {
    ISCS4 public immutable enforcement;
    address[] public pools;
    mapping(address => bool) public isPool;

    event PoolCreated(address indexed pool, address[] partners);

    error InvalidParameters();
    error InvalidProfitShares();

    constructor(address _enforcement) {
        enforcement = ISCS4(_enforcement);
    }

    function createPool(
        address asset,
        address[] memory partners,
        uint256[] memory profitSharesBps,
        string memory name,
        string memory symbol
    ) external returns (address pool) {
        if (asset == address(0) || partners.length == 0) {
            revert InvalidParameters();
        }

        if (partners.length != profitSharesBps.length) {
            revert InvalidParameters();
        }

        uint256 totalShares;
        for (uint256 i = 0; i < profitSharesBps.length; i++) {
            totalShares += profitSharesBps[i];
        }
        if (totalShares != 10000) revert InvalidProfitShares();

        pool = address(new MusharakahPool(
            asset,
            partners,
            profitSharesBps,
            address(enforcement),
            name,
            symbol
        ));

        pools.push(pool);
        isPool[pool] = true;

        emit PoolCreated(pool, partners);
    }

    function getPoolCount() external view returns (uint256) {
        return pools.length;
    }

    function getPool(uint256 index) external view returns (address) {
        return pools[index];
    }
}
