// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ISCS2
 * @notice Interface for Musharakah (joint venture) contracts based on AAOIFI Sharia Standard #12
 * @dev Implements joint venture capital model with mandatory proportional loss allocation based on AAOIFI principles
 */
interface ISCS2 {
    /// @notice Partner information
    struct Partner {
        uint256 capitalContribution;
        uint256 profitShareBps;
        bool active;
    }

    /// @notice Emitted when a partner is added
    event PartnerAdded(address indexed partner, uint256 capital, uint256 profitShareBps);
    
    /// @notice Emitted when a partner is removed
    event PartnerRemoved(address indexed partner, uint256 returnedCapital);
    
    /// @notice Emitted when profits are distributed
    event ProfitDistributed(address indexed partner, uint256 amount);
    
    /// @notice Emitted when losses are allocated
    event LossAllocated(address indexed partner, uint256 amount);

    /// @notice Returns total capital in the partnership
    function totalCapital() external view returns (uint256);
    
    /// @notice Returns partner information
    function partners(address partner) external view returns (Partner memory);
    
    /// @notice Returns number of active partners
    function partnerCount() external view returns (uint256);
    
    /// @notice Add a new partner to the Musharakah
    /// @param partner Address of the partner
    /// @param capital Capital contribution
    /// @param profitShareBps Profit share in basis points
    function addPartner(address partner, uint256 capital, uint256 profitShareBps) external;
    
    /// @notice Remove a partner from the Musharakah
    /// @param partner Address of the partner to remove
    function removePartner(address partner) external;
    
    /// @notice Distribute profits according to agreed ratios
    /// @param totalProfit Total profit to distribute
    function distributeProfit(uint256 totalProfit) external;
    
    /// @notice Allocate losses proportionally to capital (based on AAOIFI standards)
    /// @param totalLoss Total loss to allocate
    function allocateLoss(uint256 totalLoss) external;
    
    /// @notice Claim profit share
    function claimProfit() external returns (uint256 amount);
}
