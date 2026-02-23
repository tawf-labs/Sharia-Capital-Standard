# SCS-2: Musharakah Standard

## Overview

SCS-2 implements AAOIFI Sharia Standard #12 (Musharakah) - a joint venture partnership where multiple partners contribute capital and share profits/losses.

## Core Principles

### Key Differences from Mudarabah

| Aspect | Mudarabah (SCS-1) | Musharakah (SCS-2) |
|--------|-------------------|---------------------|
| Partners | 2 (manager + provider) | Multiple (2+) |
| Capital | Provider only | All partners |
| Profit Ratio | Pre-agreed | Pre-agreed (flexible) |
| Loss Ratio | 100% provider | Proportional to capital |
| Management | Manager only | Any partner |

### AAOIFI Requirements

1. **All Partners Contribute Capital**: Every partner must invest
2. **Flexible Profit Ratios**: Can differ from capital ratios
3. **Proportional Loss Allocation**: MUST match capital contribution ratios
4. **Shared Management**: All partners can participate in decisions

## Implementation

### MusharakahPool.sol

ERC-20 compliant multi-partner pool with proportional loss allocation.

**Key Features:**
- Multi-partner support (2+ partners)
- Flexible profit-sharing ratios
- Proportional loss allocation (AAOIFI compliant)
- NAV-based share accounting
- Partner-based access control

**Functions:**

```solidity
// Partner functions
function contributeCapital(uint256 amount) external returns (uint256 shares);
function withdrawCapital(uint256 shares) external returns (uint256 amount);
function deployCapital(address strategy, uint256 amount) external;
function returnCapital(uint256 amount) external;
function distributeProfits() external;
function allocateLoss(uint256 loss) external;
function terminate() external;

// View functions
function getPartners() external view returns (address[] memory);
function getPartnerInfo(address partner) external view returns (uint256, uint256, uint256);
function partnerCount() external view returns (uint256);
function availableCapital() public view returns (uint256);
function calculateNAV() external view returns (uint256);
```

### MusharakahFactory.sol

Factory for creating AAOIFI-compliant Musharakah pools.

**Functions:**

```solidity
function createPool(
    address asset,
    address[] memory partners,
    uint256[] memory profitSharesBps,
    string memory name,
    string memory symbol
) external returns (address pool);
```

## Usage Example

```solidity
// Deploy factory
MusharakahFactory factory = new MusharakahFactory(enforcementAddress);

// Setup partners (50%, 30%, 20% profit shares)
address[] memory partners = new address[](3);
partners[0] = partner1;
partners[1] = partner2;
partners[2] = partner3;

uint256[] memory profitShares = new uint256[](3);
profitShares[0] = 5000; // 50%
profitShares[1] = 3000; // 30%
profitShares[2] = 2000; // 20%

// Create pool
address pool = factory.createPool(
    usdcAddress,
    partners,
    profitShares,
    "USDC Musharakah",
    "MSP-USDC"
);

MusharakahPool musharakah = MusharakahPool(pool);

// Partners contribute capital
usdc.approve(pool, 1000e6);
musharakah.contributeCapital(1000e6); // Partner 1

usdc.approve(pool, 500e6);
musharakah.contributeCapital(500e6); // Partner 2

// Deploy capital
musharakah.deployCapital(strategyAddress, 750e6);

// Distribute profits (50%, 30%, 20%)
musharakah.distributeProfits();

// Allocate losses (proportional to capital: 66.67%, 33.33%)
musharakah.allocateLoss(100e6);
```

## AAOIFI Compliance

### Sharia Standard #12 (Musharakah)

| Requirement | Implementation |
|-------------|----------------|
| All partners contribute capital | ✅ `contributeCapital()` for each partner |
| Profit ratio can differ from capital | ✅ Flexible `profitSharesBps` array |
| Loss ratio MUST equal capital ratio | ✅ Proportional calculation in `allocateLoss()` |
| Shared management rights | ✅ All partners can call management functions |
| No guaranteed returns | ✅ Enforced by SCS-4 |
| Transparent accounting | ✅ NAV calculation, events |

### FAS #9 (Musharakah Financing)

- Multi-partner capital tracking
- Proportional loss allocation
- Profit distribution by agreement
- Partner contribution history

## Key Implementation Details

### 1. Proportional Loss Allocation

```solidity
uint256 partnerLoss = (loss * info.capitalContributed) / totalCapital;
```

This ensures losses are allocated proportionally to capital contributions, as required by AAOIFI.

### 2. Flexible Profit Sharing

```solidity
uint256 profitShare = (totalProfit * partnerInfo[partner].profitShareBps) / 10000;
```

Profit shares can differ from capital ratios, allowing partners to negotiate based on expertise, effort, or other factors.

### 3. Partner Access Control

```solidity
modifier onlyPartner() {
    if (!partnerInfo[msg.sender].isPartner) revert Unauthorized();
    _;
}
```

All management functions require partner status.

## Security Considerations

1. **ReentrancyGuard**: All state-changing functions protected
2. **Partner Validation**: Partners set at creation, cannot be changed
3. **Profit Share Validation**: Must sum to exactly 10000 (100%)
4. **Input Validation**: Amount checks, zero address checks
5. **Safe ERC20**: Using OpenZeppelin SafeERC20
6. **Overflow Protection**: Solidity 0.8.26 built-in

## Gas Optimization

- Immutable variables for addresses
- Basis points (10000 = 100%)
- Minimal storage reads
- Efficient loop operations

## Testing

13 tests covering:
- Pool creation with multiple partners
- Capital contributions (multiple partners)
- Capital withdrawal
- Capital deployment/return
- Profit distribution (flexible ratios)
- Loss allocation (proportional)
- Access control
- Edge cases
- Fuzz testing

**Test Coverage**: 100%

## Comparison with SCS-1 (Mudarabah)

| Feature | SCS-1 Mudarabah | SCS-2 Musharakah |
|---------|-----------------|------------------|
| Partners | 2 fixed roles | 2+ equal partners |
| Capital Source | Provider only | All partners |
| Profit Ratio | Fixed at creation | Fixed at creation |
| Loss Allocation | 100% provider | Proportional to capital |
| Management | Manager only | All partners |
| Use Case | Fund management | Joint ventures |

## Limitations

1. **Fixed Partners**: Partners set at creation, cannot add/remove
2. **Fixed Profit Ratios**: Cannot change after creation
3. **Manual Distribution**: Profits must be manually distributed
4. **No Weighted Voting**: All partners have equal management rights

## Future Enhancements

- Dynamic partner addition/removal
- Adjustable profit ratios (with consensus)
- Automated profit distribution
- Weighted voting based on capital
- Time-locked deployments
- Governance integration (SCS-5)

## References

- [AAOIFI Sharia Standard #12](https://aaoifi.com/product/shari-a-standards/?lang=en)
- [AAOIFI FAS #9](https://aaoifi.com/product/financial-accounting-standards/?lang=en)
- [ERC-20 Standard](https://eips.ethereum.org/EIPS/eip-20)
