// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ISCS1
 * @notice Interface for Mudarabah (profit-sharing) contracts per AAOIFI Sharia Standard #8
 * @dev Implements manager-investor profit-sharing model with strict AAOIFI compliance
 */
interface ISCS1 {
    /// @notice Emitted when capital is deposited by Rabb al-Mal (capital provider)
    event CapitalDeposited(address indexed provider, uint256 amount, uint256 shares);
    
    /// @notice Emitted when capital is withdrawn
    event CapitalWithdrawn(address indexed provider, uint256 amount, uint256 shares);
    
    /// @notice Emitted when Mudarib deploys capital to strategy
    event CapitalDeployed(uint256 indexed deploymentId, uint256 amount, address strategy);
    
    /// @notice Emitted when capital returns from strategy
    event CapitalReturned(uint256 indexed deploymentId, uint256 returned, int256 profitLoss);
    
    /// @notice Emitted when profits are distributed
    event ProfitsDistributed(uint256 capitalProviderShare, uint256 mudaribShare);
    
    /// @notice Emitted when losses are allocated
    event LossAllocated(uint256 amount);

    /// @notice Returns the capital provider (Rabb al-Mal) address
    function capitalProvider() external view returns (address);
    
    /// @notice Returns the manager (Mudarib) address
    function mudarib() external view returns (address);
    
    /// @notice Returns total capital in the pool
    function totalCapital() external view returns (uint256);
    
    /// @notice Returns capital currently deployed to strategies
    function deployedCapital() external view returns (uint256);
    
    /// @notice Returns capital provider's profit share in basis points (e.g., 7000 = 70%)
    function capitalProviderShareBps() external view returns (uint256);
    
    /// @notice Returns Mudarib's profit share in basis points (e.g., 3000 = 30%)
    function mudaribShareBps() external view returns (uint256);
    
    /// @notice Deposit capital into the pool
    /// @param amount Amount of capital to deposit
    function deposit(uint256 amount) external returns (uint256 shares);
    
    /// @notice Withdraw capital from the pool
    /// @param shares Amount of shares to redeem
    function withdraw(uint256 shares) external returns (uint256 amount);
    
    /// @notice Deploy capital to investment strategy (Mudarib only)
    /// @param strategy Address of the strategy
    /// @param amount Amount to deploy
    function deployCapital(address strategy, uint256 amount) external returns (uint256 deploymentId);
    
    /// @notice Return capital from strategy (Mudarib only)
    /// @param deploymentId ID of the deployment
    /// @param returnedAmount Amount returned (including profit/loss)
    function returnCapital(uint256 deploymentId, uint256 returnedAmount) external;
    
    /// @notice Distribute accumulated profits
    function distributeProfits() external;
    
    /// @notice Claim profit share
    function claimProfit() external returns (uint256 amount);
}
