// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title ISCS3
 * @notice Interface for Profit-Sharing Vault Engine per AAOIFI FAS #27
 * @dev Extends ERC-4626 with epoch-based accounting and NAV calculation
 */
interface ISCS3 is IERC4626 {
    /// @notice Epoch information
    struct Epoch {
        uint256 startTime;
        uint256 endTime;
        uint256 startingNAV;
        uint256 endingNAV;
        bool finalized;
    }

    /// @notice Strategy information
    struct Strategy {
        address strategyAddress;
        uint256 allocation;
        bool active;
    }

    /// @notice Emitted when a new epoch begins
    event EpochStarted(uint256 indexed epochId, uint256 startTime);
    
    /// @notice Emitted when an epoch is finalized
    event EpochFinalized(uint256 indexed epochId, uint256 nav);
    
    /// @notice Emitted when a strategy is added
    event StrategyAdded(address indexed strategy, uint256 allocation);
    
    /// @notice Emitted when a strategy is removed
    event StrategyRemoved(address indexed strategy);
    
    /// @notice Emitted when strategies are rebalanced
    event StrategyRebalanced(address indexed strategy, uint256 newAllocation);

    /// @notice Returns current epoch ID
    function currentEpoch() external view returns (uint256);
    
    /// @notice Returns epoch information
    function epochs(uint256 epochId) external view returns (Epoch memory);
    
    /// @notice Returns current Net Asset Value
    function calculateNAV() external view returns (uint256);
    
    /// @notice Start a new epoch
    function startEpoch() external;
    
    /// @notice Finalize current epoch and record NAV
    function finalizeEpoch() external;
    
    /// @notice Add investment strategy
    /// @param strategy Address of the strategy contract
    /// @param allocation Allocation in basis points
    function addStrategy(address strategy, uint256 allocation) external;
    
    /// @notice Remove investment strategy
    /// @param strategy Address of the strategy to remove
    function removeStrategy(address strategy) external;
    
    /// @notice Rebalance strategy allocations
    /// @param strategies Array of strategy addresses
    /// @param allocations Array of new allocations in basis points
    function rebalanceStrategies(address[] calldata strategies, uint256[] calldata allocations) external;
}
