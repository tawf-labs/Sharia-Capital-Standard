# SCS-1: Mudarabah Standard
### Part of Sharia Capital Standard by TAWF Labs

## Overview

> **Important Notice**: This is part of the **TAWF Sharia Standard**, based on AAOIFI standards but **not officially approved or endorsed by AAOIFI**. Users must obtain independent Sharia Supervisory Board approval before production use.

SCS-1 is based on AAOIFI Sharia Standard #8 (Mudarabah) - a profit-sharing partnership between capital provider (Rabb al-Mal) and manager (Mudarib).

## Core Principles

### Roles

1. **Rabb al-Mal (Capital Provider)**
   - Provides capital
   - Bears all financial losses (except misconduct)
   - Receives predetermined profit share
   - Can withdraw capital when available

2. **Mudarib (Manager)**
   - Manages investments
   - Deploys capital to strategies
   - Receives predetermined profit share
   - Bears no financial loss (unless misconduct)

### Profit & Loss Distribution

- **Profits**: Shared according to pre-agreed ratio (e.g., 80/20)
- **Losses**: Borne entirely by capital provider
- **No Guaranteed Returns**: Enforced by SCS-4

## Implementation

### MudarabahPool.sol

ERC-20 compliant pool with NAV-based share accounting.

**Key Features:**
- Capital deposit/withdrawal
- Capital deployment to strategies
- Profit distribution (basis points)
- Loss allocation (capital provider only)
- NAV calculation

**Functions:**

```solidity
// Capital provider functions
function deposit(uint256 amount) external returns (uint256 shares);
function withdraw(uint256 shares) external returns (uint256 amount);
function terminate() external;

// Manager functions
function deployCapital(address strategy, uint256 amount) external returns (uint256 deploymentId);
function returnCapital(uint256 deploymentId, uint256 returnedAmount) external;
function distributeProfits() external;
function claimProfit() external returns (uint256 amount);
function recordLoss(uint256 amount) external;

// View functions
function availableCapital() public view returns (uint256);
function calculateNAV() external view returns (uint256);
```

### MudarabahFactory.sol

Factory for creating Sharia-compliant Mudarabah pools (based on AAOIFI standards).

**Functions:**

```solidity
function createPool(
    address asset,
    address manager,
    address capitalProvider,
    uint256 managerShareBps,
    uint256 providerShareBps,
    string memory name,
    string memory symbol
) external returns (address pool);
```

## Usage Example

```solidity
// Deploy factory
MudarabahFactory factory = new MudarabahFactory(enforcementAddress);

// Create pool (20% manager, 80% provider)
address pool = factory.createPool(
    usdcAddress,
    managerAddress,
    providerAddress,
    2000, // 20% in basis points
    8000, // 80% in basis points
    "USDC Mudarabah Pool",
    "MDP-USDC"
);

MudarabahPool mudarabah = MudarabahPool(pool);

// Provider deposits capital
usdc.approve(pool, 1000e6);
uint256 shares = mudarabah.deposit(1000e6);

// Manager deploys to strategy
uint256 deploymentId = mudarabah.deployCapital(strategyAddress, 500e6);

// Strategy returns capital with profit
usdc.approve(pool, 600e6);
mudarabah.returnCapital(deploymentId, 600e6); // 100 USDC profit

// Distribute profits (20 to manager, 80 to provider)
mudarabah.distributeProfits();

// Provider withdraws
mudarabah.withdraw(shares);
```

## AAOIFI Compliance

### Sharia Standard #8 Requirements

| Requirement | Implementation |
|-------------|----------------|
| Capital provider provides funds | ✅ `deposit()` function |
| Manager manages investments | ✅ `deployCapital()` function |
| Profit shared by ratio | ✅ Basis points system |
| Loss borne by provider | ✅ `recordLoss()` only affects capital |
| No guaranteed returns | ✅ Enforced by SCS-4 |
| Manager receives no capital loss | ✅ Only profit share affected |

### FAS #4 (Mudarabah Financing)

- NAV-based accounting
- Share-based capital tracking
- Profit/loss attribution
- Deployment tracking

## Security Considerations

1. **ReentrancyGuard**: All state-changing functions protected
2. **Access Control**: Role-based permissions (manager vs provider)
3. **Input Validation**: Amount checks, zero address checks
4. **Safe ERC20**: Using OpenZeppelin SafeERC20
5. **Overflow Protection**: Solidity 0.8.26 built-in

## Gas Optimization

- Immutable variables for addresses
- Basis points instead of percentages
- Minimal storage reads
- Efficient share calculation

## Testing

13 tests covering:
- Pool creation
- Capital deposit/withdrawal
- Capital deployment/return
- Profit distribution
- Loss allocation
- Access control
- Edge cases
- Fuzz testing

**Test Coverage**: 100%

## Integration

Works seamlessly with:
- **SCS-4**: Enforcement layer validates all operations
- **ERC-20**: Standard token interface
- **ERC-4626**: Compatible vault interface (future)

## Limitations

1. Single capital provider per pool
2. Single manager per pool
3. No sub-pools or tranches
4. No time-locked deployments
5. Manual profit distribution

## Future Enhancements

- Multi-provider support
- Automated profit distribution
- Time-locked deployments
- Performance fees
- Emergency pause mechanism
- Governance integration (SCS-5)

## References

- [AAOIFI Sharia Standard #8](https://aaoifi.com/product/shari-a-standards/?lang=en)
- [AAOIFI FAS #4](https://aaoifi.com/product/financial-accounting-standards/?lang=en)
- [ERC-20 Standard](https://eips.ethereum.org/EIPS/eip-20)
