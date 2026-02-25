// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IShariaCompliant
 * @notice Base interface for Sharia-compliant contracts based on AAOIFI standards
 * @dev All SCS contracts should implement this interface
 * 
 * IMPORTANT: This is part of the TAWF Sharia Standard, based on AAOIFI standards
 * but NOT officially approved or endorsed by AAOIFI. This interface is designed based on
 * AAOIFI principles for blockchain-based Islamic finance. Users must obtain independent
 * Sharia Supervisory Board approval before production use.
 */
interface IShariaCompliant {
    /// @notice Returns the AAOIFI standard(s) this contract is based on
    /// @return standards Array of AAOIFI standard identifiers (e.g., [8, 12] for Sharia #8 and #12)
    function getShariaStandards() external pure returns (uint256[] memory standards);
    
    /// @notice Returns whether this contract is Sharia compliant (based on AAOIFI standards)
    /// @return compliant True if compliant
    function isShariaCompliant() external view returns (bool compliant);
    
    /// @notice Returns the governance contract address
    /// @return governance Address of the SCS5 governance contract
    function governanceContract() external view returns (address governance);
}
