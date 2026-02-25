# SCS-5: Sharia Governance Standard
### Part of Sharia Capital Standard by TAWF Labs

## Overview

> **Important Notice**: This is part of the **TAWF Sharia Standard**, based on AAOIFI standards but **not officially approved or endorsed by AAOIFI**. Users must obtain independent Sharia Supervisory Board approval before production use.

SCS-5 is based on AAOIFI Governance Standard #3 with Sharia Supervisory Board (SSB) integration, multi-signature approval system, and compliance oversight.

## Core Principles

### Sharia Supervisory Board (SSB)

The SSB is responsible for:
- **Sharia Compliance Oversight**: Ensuring all operations comply with Islamic law
- **Investment Approval**: Multi-signature approval for investments
- **Asset Screening**: Prohibiting non-compliant assets
- **Financial Ratio Validation**: Ensuring financial standards based on AAOIFI principles
- **Fatwa Issuance**: Providing religious rulings on financial matters

### Multi-Signature Governance

- **Quorum-Based Decisions**: Requires minimum approvals (e.g., 2 of 3)
- **Proposal System**: Submit, approve, and execute proposals
- **Transparent Process**: All decisions recorded on-chain
- **Member Management**: Add/remove SSB members

## Implementation

### ShariaBoard.sol

Multi-signature governance contract for SSB oversight.

**Key Features:**
- Multi-signature proposal system
- Configurable approval threshold
- Member management
- Proposal execution
- Strategy approval
- Financial ratio validation

**Functions:**

```solidity
// Proposal Management
function submitProposal(string memory description, address target, bytes memory data, ProposalType proposalType) external returns (bytes32);
function approveProposal(bytes32 proposalId) external;
function executeProposal(bytes32 proposalId) external returns (bool);

// Member Management
function addMember(address member) external;
function removeMember(address member) external;
function setRequiredApprovals(uint256 _requiredApprovals) external;

// ISCS5 Interface
function addSSBMember(address member) external;
function removeSSBMember(address member) external;
function approveStrategy(bytes32 strategyHash) external;
function isStrategyApproved(bytes32 strategyHash) external view returns (bool);
function checkFinancialRatios(FinancialRatios calldata ratios) external pure returns (bool, string memory);
```

### ShariaGovernance.sol

Compliance layer for asset screening and financial validation (based on AAOIFI Governance Standard #3).

**Key Features:**
- Asset prohibition/permission
- Asset screening system
- Financial ratio validation (debt, interest)
- Integration with ShariaBoard

**Functions:**

```solidity
// Asset Management
function prohibitAsset(address asset) external;
function permitAsset(address asset) external;
function screenAsset(address asset, bool compliant, string memory reason) external;
function validateAsset(address asset) external view returns (bool);

// Financial Validation
function validateFinancialRatios(uint256 totalAssets, uint256 totalDebt, uint256 interestIncome) external view returns (bool);
function setMaxDebtRatio(uint256 ratio) external;
function setMaxInterestRatio(uint256 ratio) external;
```

## Usage Example

```solidity
// Deploy Sharia Board with 3 members, 2 required approvals
address[] memory members = new address[](3);
members[0] = scholar1;
members[1] = scholar2;
members[2] = scholar3;

ShariaBoard board = new ShariaBoard(members, 2);
ShariaGovernance governance = new ShariaGovernance(address(board));

// Transfer ownership to board
governance.transferOwnership(address(board));

// Submit proposal to change debt ratio
bytes32 proposalId = board.submitProposal(
    "Increase max debt ratio to 35%",
    address(governance),
    abi.encodeWithSignature("setMaxDebtRatio(uint256)", 3500),
    ShariaBoard.ProposalType.PARAMETER_CHANGE
);

// Members approve
board.approveProposal(proposalId); // Member 1
board.approveProposal(proposalId); // Member 2

// Execute (requires 2 approvals)
board.executeProposal(proposalId);

// Screen an asset
governance.screenAsset(usdcAddress, true, "Stablecoin - Compliant");

// Validate financial ratios
bool compliant = governance.validateFinancialRatios(
    1000e18, // total assets
    300e18,  // debt (30%)
    200e18   // interest income (20%)
);
```

## AAOIFI Compliance

### Governance Standard #3 (Internal Sharia Review)

| Requirement | Implementation |
|-------------|----------------|
| SSB oversight | ✅ ShariaBoard contract |
| Multi-member board | ✅ Configurable members |
| Quorum-based decisions | ✅ Required approvals |
| Investment approval | ✅ Proposal system |
| Asset screening | ✅ ShariaGovernance |
| Financial ratio validation | ✅ Debt & interest checks |
| Transparent reporting | ✅ On-chain records |

### AAOIFI Financial Ratios

| Ratio | Limit | Implementation |
|-------|-------|----------------|
| Debt Ratio | ≤ 33% | `maxDebtRatio = 3300` (basis points) |
| Interest Income | ≤ 30% | `maxInterestRatio = 3000` (basis points) |
| Interest-bearing Debt | ≤ 33% | Validated in `checkFinancialRatios()` |

## Key Implementation Details

### 1. Multi-Signature Proposal System

```solidity
struct Proposal {
    string description;
    address target;
    bytes data;
    uint256 approvals;
    bool executed;
    ProposalType proposalType;
}
```

Proposals require quorum approvals before execution.

### 2. Financial Ratio Validation

```solidity
uint256 debtRatio = (totalDebt * 10000) / totalAssets;
if (debtRatio > maxDebtRatio) revert RatioExceeded();

uint256 interestRatio = (interestIncome * 10000) / totalAssets;
if (interestRatio > maxInterestRatio) revert RatioExceeded();
```

Ensures AAOIFI compliance for financial metrics.

### 3. Asset Screening

```solidity
struct AssetScreening {
    bool screened;
    bool compliant;
    uint256 screenedAt;
    string reason;
}
```

Tracks screening status and compliance reasoning.

## Security Considerations

1. **Ownable**: Admin functions restricted to owner
2. **Multi-Signature**: Prevents single-point-of-failure
3. **Proposal Execution**: Can fail gracefully
4. **Member Validation**: Zero address checks
5. **Approval Tracking**: Prevents double-approval

## Gas Optimization

- Immutable enforcement address
- Basis points for ratios (10000 = 100%)
- Minimal storage reads
- Efficient proposal tracking

## Testing

17 tests covering:
- Board creation with members
- Proposal submission
- Proposal approval (multi-sig)
- Proposal execution
- Member management
- Asset prohibition/screening
- Asset validation
- Financial ratio validation
- Access control
- Edge cases
- Fuzz testing

**Test Coverage**: 100%

## Integration with Other Standards

### With SCS-1 (Mudarabah)
- SSB approves manager selection
- Validates profit-sharing ratios
- Screens investment strategies

### With SCS-2 (Musharakah)
- Approves partner additions
- Validates capital contributions
- Screens joint ventures

### With SCS-3 (Vault Engine)
- Approves strategy additions
- Validates performance fees
- Screens deployed assets

### With SCS-4 (Enforcement)
- Validates compliance rules
- Enforces Sharia standards
- Prevents prohibited operations

## Limitations

1. **Fixed Quorum**: Cannot change mid-proposal
2. **No Proposal Cancellation**: Once submitted, cannot cancel
3. **Simple Execution**: No timelock or delay
4. **Manual Screening**: Assets must be manually screened

## Future Enhancements

- Timelock for proposal execution
- Proposal cancellation mechanism
- Automated asset screening (oracle integration)
- Weighted voting based on expertise
- Fatwa documentation system
- Audit trail reporting
- Emergency pause mechanism

## References

- [AAOIFI Governance Standard #3](https://aaoifi.com/product/governance-standards-for-islamic-financial-institutions/?lang=en)
- [AAOIFI Financial Ratios](https://aaoifi.com/product/financial-accounting-standards/?lang=en)
- [Multi-Signature Wallets](https://docs.openzeppelin.com/contracts/4.x/api/governance)
