// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ISCS5
 * @notice Interface for Sharia Governance & Sharia Supervisory Board based on AAOIFI Governance Standard #3
 * @dev Implements SSB oversight, multi-signature approval, and compliance validation
 */
interface ISCS5 {
    /// @notice SSB decision record
    struct SSBDecision {
        bytes32 decisionId;
        string description;
        uint256 approvalCount;
        bool executed;
        uint256 timestamp;
    }

    /// @notice Financial ratios for Sharia compliance (based on AAOIFI standards)
    struct FinancialRatios {
        uint256 totalAssets;
        uint256 interestBearingDebt;
        uint256 totalIncome;
        uint256 interestIncome;
    }

    /// @notice Emitted when SSB member is added
    event SSBMemberAdded(address indexed member);
    
    /// @notice Emitted when SSB member is removed
    event SSBMemberRemoved(address indexed member);
    
    /// @notice Emitted when strategy is approved
    event StrategyApproved(bytes32 indexed strategyHash, uint256 approvalCount);
    
    /// @notice Emitted when asset is prohibited
    event AssetProhibited(address indexed asset, string reason);
    
    /// @notice Emitted when asset is allowed
    event AssetAllowed(address indexed asset);

    /// @notice Minimum SSB members required
    function MIN_SSB_MEMBERS() external view returns (uint256);
    
    /// @notice SSB quorum required for decisions
    function SSB_QUORUM() external view returns (uint256);
    
    /// @notice Check if address is SSB member
    function isSSBMember(address member) external view returns (bool);
    
    /// @notice Returns current SSB member count
    function ssbMemberCount() external view returns (uint256);
    
    /// @notice Add SSB member
    /// @param member Address of the new SSB member
    function addSSBMember(address member) external;
    
    /// @notice Remove SSB member
    /// @param member Address of the SSB member to remove
    function removeSSBMember(address member) external;
    
    /// @notice Approve investment strategy (requires SSB quorum)
    /// @param strategyHash Hash of the strategy details
    function approveStrategy(bytes32 strategyHash) external;
    
    /// @notice Check if strategy is approved
    /// @param strategyHash Hash of the strategy
    /// @return approved Whether strategy has SSB approval
    function isStrategyApproved(bytes32 strategyHash) external view returns (bool approved);
    
    /// @notice Validate asset against prohibited sectors (based on AAOIFI standards)
    /// @param asset Address of the asset
    /// @return allowed Whether asset is allowed
    /// @return reason Reason if not allowed
    function validateAsset(address asset) external view returns (bool allowed, string memory reason);
    
    /// @notice Check financial ratios for Sharia compliance (based on AAOIFI standards)
    /// @param ratios Financial ratios to validate
    /// @return compliant Whether ratios meet Sharia standards
    /// @return reason Reason if not compliant
    function checkFinancialRatios(FinancialRatios calldata ratios) 
        external 
        pure 
        returns (bool compliant, string memory reason);
}
