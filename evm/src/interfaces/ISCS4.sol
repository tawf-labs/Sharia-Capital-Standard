// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ISCS4
 * @notice Interface for Non-Guaranteed Return Enforcement Layer
 * @dev Validates and enforces Sharia compliance rules based on AAOIFI standards across all SCS contracts
 */
interface ISCS4 {
    /// @notice Validation result
    struct ValidationResult {
        bool isCompliant;
        string reason;
    }

    /// @notice Emitted when a deployment is validated
    event DeploymentValidated(address indexed pool, uint256 amount, bool compliant);
    
    /// @notice Emitted when a contract is registered
    event ContractRegistered(address indexed contractAddress, uint8 scsType);
    
    /// @notice Emitted when a contract is deregistered
    event ContractDeregistered(address indexed contractAddress);

    /// @notice Validate capital deployment (no guaranteed returns)
    /// @param amount Deployment amount
    /// @param expectedReturn Expected return (must be 0)
    /// @return result Validation result
    function validateDeployment(uint256 amount, uint256 expectedReturn) 
        external 
        view 
        returns (ValidationResult memory result);
    
    /// @notice Validate profit-sharing ratio
    /// @param capitalShareBps Capital provider share in basis points
    /// @param mudaribShareBps Mudarib share in basis points
    /// @return result Validation result
    function validateProfitRatio(uint256 capitalShareBps, uint256 mudaribShareBps) 
        external 
        pure 
        returns (ValidationResult memory result);
    
    /// @notice Validate loss allocation for Musharakah
    /// @param partnerCapital Partner's capital contribution
    /// @param totalCapital Total partnership capital
    /// @param partnerLoss Partner's allocated loss
    /// @param totalLoss Total loss
    /// @return result Validation result
    function validateLossAllocation(
        uint256 partnerCapital,
        uint256 totalCapital,
        uint256 partnerLoss,
        uint256 totalLoss
    ) external pure returns (ValidationResult memory result);
    
    /// @notice Check if contract is registered and compliant
    /// @param contractAddress Address to check
    /// @return isRegistered Whether contract is registered
    function isCompliantContract(address contractAddress) external view returns (bool isRegistered);
    
    /// @notice Register a compliant SCS contract
    /// @param contractAddress Address of the contract
    /// @param scsType Type of SCS (1=Mudarabah, 2=Musharakah, 3=Vault, 5=Governance)
    function registerContract(address contractAddress, uint8 scsType) external;
    
    /// @notice Deregister a contract
    /// @param contractAddress Address of the contract
    function deregisterContract(address contractAddress) external;
}
