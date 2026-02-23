// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IAAOIFICompliant
 * @notice Base interface for AAOIFI-compliant contracts
 * @dev All SCS contracts should implement this interface
 */
interface IAAOIFICompliant {
    /// @notice Returns the AAOIFI standard(s) this contract implements
    /// @return standards Array of AAOIFI standard identifiers (e.g., [8, 12] for Sharia #8 and #12)
    function getAAOIFIStandards() external pure returns (uint256[] memory standards);
    
    /// @notice Returns whether this contract is AAOIFI compliant
    /// @return compliant True if compliant
    function isAAOIFICompliant() external view returns (bool compliant);
    
    /// @notice Returns the governance contract address
    /// @return governance Address of the SCS5 governance contract
    function governanceContract() external view returns (address governance);
}
