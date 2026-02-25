# SCS-3: Vault Engine Standard
### Part of Sharia Capital Standard by TAWF Labs

## Overview

> **Important Notice**: This is part of the **TAWF Sharia Standard**, based on AAOIFI standards but **not officially approved or endorsed by AAOIFI**. Users must obtain independent Sharia Supervisory Board approval before production use.

SCS-3 implements an ERC-4626 compliant tokenized vault with epoch-based accounting, multi-strategy management, and NAV calculation based on AAOIFI FAS #27.

## Core Principles

### ERC-4626 Compliance

Standard tokenized vault interface for:
- Deposit/withdrawal of assets
- Share-based accounting
- Standardized vault operations
- Composability with DeFi protocols

### Epoch-Based Accounting

- **Epochs**: Fixed time periods (default 7 days)
- **NAV Tracking**: Net Asset Value calculated per epoch
- **Performance Fees**: Calculated on profits per epoch
- **Transparent Reporting**: Historical epoch data

### Multi-Strategy Management

- **Strategy Allocation**: Deploy capital to multiple strategies
- **Risk Diversification**: Spread capital across strategies
- **Performance Tracking**: Monitor returns per strategy
- **Dynamic Rebalancing**: Adjust allocations as needed

## Implementation

### VaultEngine.sol

ERC-4626 compliant vault with advanced features.

**Key Features:**
- ERC-4626 standard compliance
- Epoch-based accounting (7-day default)
- Multi-strategy capital deployment
- Performance fee calculation (10% default)
- Management fee support (2% default)
- NAV calculation
- Pausable for emergencies

**Functions:**

```solidity
// ERC-4626 Standard
function deposit(uint256 assets, address receiver) external returns (uint256 shares);
function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
function totalAssets() public view returns (uint256);

// Strategy Management
function addStrategy(address strategy, uint256 allocationBps) external;
function removeStrategy(address strategy) external;
function deployToStrategy(address strategy, uint256 amount) external;
function recallFromStrategy(address strategy, uint256 amount) external;

// Epoch Management
function startNewEpoch() external;
function calculateNAV() public view returns (uint256);
function getEpochData(uint256 epoch) external view returns (...);

// Configuration
function setPerformanceFee(uint256 feeBps) external;
function setEpochDuration(uint256 duration) external;
function pause() external;
function unpause() external;
```

## Usage Example

```solidity
// Deploy vault
VaultEngine vault = new VaultEngine(
    usdcAddress,
    enforcementAddress,
    "USDC Vault",
    "vUSDC"
);

// User deposits
usdc.approve(address(vault), 1000e6);
uint256 shares = vault.deposit(1000e6, user);

// Owner adds strategies
vault.addStrategy(strategy1, 5000); // 50% allocation
vault.addStrategy(strategy2, 3000); // 30% allocation

// Deploy capital to strategies
vault.deployToStrategy(strategy1, 500e6);
vault.deployToStrategy(strategy2, 300e6);

// After 7 days, start new epoch
vm.warp(block.timestamp + 7 days);
vault.startNewEpoch(); // Calculates performance fees

// User withdraws
vault.withdraw(shares, user, user);
```

## AAOIFI Compliance

### FAS #27 (Investment Accounts)

| Requirement | Implementation |
|-------------|----------------|
| NAV calculation | ✅ `calculateNAV()` function |
| Periodic reporting | ✅ Epoch-based system |
| Performance tracking | ✅ Per-epoch NAV tracking |
| Fee transparency | ✅ Performance fee calculation |
| Asset valuation | ✅ Total assets = balance + deployed |

### Integration with SCS-1 & SCS-2

The vault can hold:
- **Mudarabah pools** (SCS-1) as strategies
- **Musharakah pools** (SCS-2) as strategies
- Direct DeFi protocols
- Mixed portfolio approach

## Key Implementation Details

### 1. Epoch-Based Profit Calculation

```solidity
// Profit = ending NAV - starting NAV - net deposits
uint256 netDeposits = deposits - withdrawals;
uint256 profit = nav - startNAV - netDeposits;
uint256 perfFee = (profit * performanceFeeBps) / 10000;
```

This ensures deposits/withdrawals don't count as profits.

### 2. NAV Calculation

```solidity
function calculateNAV() public view returns (uint256) {
    return IERC20(asset()).balanceOf(address(this)) + totalDeployed;
}
```

NAV = idle capital + deployed capital.

### 3. Strategy Deployment

```solidity
function deployToStrategy(address strategy, uint256 amount) external {
    enforcement.validateDeployment(amount, 0); // SCS-4 check
    strategyInfo[strategy].deployed += amount;
    totalDeployed += amount;
    IERC20(asset()).safeTransfer(strategy, amount);
}
```

All deployments validated by SCS-4 enforcement layer.

## Security Considerations

1. **ReentrancyGuard**: All state-changing functions protected
2. **Ownable**: Strategy management restricted to owner
3. **Pausable**: Emergency stop mechanism
4. **SCS-4 Integration**: No guaranteed returns enforced
5. **Safe ERC20**: Using OpenZeppelin SafeERC20
6. **Overflow Protection**: Solidity 0.8.26 built-in

## Gas Optimization

- Immutable enforcement address
- Basis points for fees (10000 = 100%)
- Minimal storage reads
- Efficient NAV calculation

## Testing

16 tests covering:
- Vault creation
- Deposit/withdrawal (ERC-4626)
- Strategy management
- Capital deployment/recall
- NAV calculation
- Epoch management
- Performance fee calculation
- Access control
- Pause/unpause
- Edge cases
- Fuzz testing

**Test Coverage**: 100%

## ERC-4626 Benefits

1. **Standardization**: Compatible with all ERC-4626 tools
2. **Composability**: Can be used in other DeFi protocols
3. **Liquidity**: Shares are transferable ERC-20 tokens
4. **Transparency**: Standard interface for vaults

## Comparison with SCS-1 & SCS-2

| Feature | SCS-1 Mudarabah | SCS-2 Musharakah | SCS-3 Vault |
|---------|-----------------|------------------|-------------|
| Standard | AAOIFI SS #8 | AAOIFI SS #12 | ERC-4626 + FAS #27 |
| Participants | 2 (manager + provider) | 2+ partners | Unlimited depositors |
| Capital Source | Provider | All partners | All depositors |
| Management | Manager | All partners | Owner |
| Strategies | Single | Single | Multiple |
| Shares | ERC-20 | ERC-20 | ERC-4626 |

## Limitations

1. **Owner-Controlled**: Only owner can manage strategies
2. **Fixed Epoch Duration**: Cannot change mid-epoch
3. **No Auto-Rebalancing**: Manual strategy rebalancing
4. **Performance Fee Cap**: Max 20%

## Future Enhancements

- Automated strategy rebalancing
- Dynamic epoch durations
- Multi-asset support
- Governance integration (SCS-5)
- Strategy performance scoring
- Risk-adjusted allocations
- Automated compounding

## References

- [ERC-4626 Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [AAOIFI FAS #27](https://aaoifi.com/product/financial-accounting-standards/?lang=en)
- [OpenZeppelin ERC4626](https://docs.openzeppelin.com/contracts/4.x/erc4626)
