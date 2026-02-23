# AAOIFI Compliance Guide

## Overview

This guide explains how the Sharia Capital Standard (SCS) implements AAOIFI (Accounting and Auditing Organization for Islamic Financial Institutions) standards for blockchain-based Islamic finance.

## Implemented AAOIFI Standards

### Sharia Standards

#### AAOIFI Sharia Standard #8: Mudarabah
**Implementation**: SCS-1 (Mudarabah Pool)

**Key Requirements**:
1. **Essential Elements (Arkan)**:
   - Rabb al-Mal (capital provider) - implemented as `capitalProvider` address
   - Mudarib (manager) - implemented as `mudarib` address
   - Capital (Maal) - tracked as `totalCapital`
   - Profit-sharing ratio - stored as `capitalProviderShareBps` and `mudaribShareBps`
   - Valid contract - enforced through smart contract deployment

2. **Capital Requirements**:
   - Must be in currency (ERC-20 tokens) or tangible assets
   - Must be determined and known at contract inception
   - Must be deliverable (not future-dated)
   - Cannot be services, debts, or intangible assets

3. **Profit Distribution**:
   - Exact profit-sharing percentage specified in basis points
   - NO guaranteed minimum returns
   - NO tiered/commission structures resembling interest
   - NO principal-indexed returns

4. **Loss Allocation**:
   - Normal losses borne 100% by capital provider
   - Mudarib liable ONLY for proven misconduct/negligence

#### AAOIFI Sharia Standard #12: Musharakah
**Implementation**: SCS-2 (Musharakah Pool)

**Key Requirements**:
1. **Partnership Structure**:
   - All partners contribute capital
   - Joint management (unless agreed otherwise)
   - Profit ratio CAN differ from capital ratio
   - Loss ratio MUST equal capital ratio (strict enforcement)

2. **Profit Distribution**:
   - Flexible allocation by mutual agreement
   - Example: Partner A (10% capital) can receive 50% profit

3. **Loss Allocation** (MANDATORY):
   - Strictly proportional to capital contribution
   - Formula: `partnerLoss = (partnerCapital / totalCapital) * totalLoss`
   - Enforced by SCS-4 validation layer
   - Example: Partner A (10% capital) MUST bear 10% of loss

#### AAOIFI Sharia Standard #17: Investment Agencies
**Implementation**: SCS-3 (Vault Engine)

**Key Requirements**:
1. **Investment Management**:
   - Clear investment mandate
   - Strategy approval process
   - Performance reporting
   - Fee structure transparency

2. **Fiduciary Duties**:
   - Act in best interest of investors
   - Avoid conflicts of interest
   - Maintain proper records
   - Provide regular disclosures

### Governance Standards

#### AAOIFI Governance Standard #3: Sharia Supervisory Board
**Implementation**: SCS-5 (AAOIFI Governance)

**Key Requirements**:
1. **SSB Composition**:
   - Minimum 3 qualified members
   - Islamic finance expertise required
   - Independence from management

2. **SSB Responsibilities**:
   - Review and approve investment strategies
   - Monitor ongoing compliance
   - Issue Sharia compliance certificates
   - Resolve Sharia-related queries

3. **Decision Making**:
   - Multi-signature approval (quorum of 2)
   - Documented decisions on-chain
   - Cannot be bypassed or overridden

### Accounting Standards

#### AAOIFI FAS #4: Mudarabah Financing
**Implementation**: SCS-5 (Disclosure Registry)

**Key Requirements**:
1. **Capital Accounts**:
   - Opening balance
   - Contributions during period
   - Withdrawals during period
   - Profit/loss for period
   - Closing balance

2. **Disclosure Requirements**:
   - Mudarib's share of profit
   - Capital provider's share of profit
   - Basis of profit distribution
   - Losses and their allocation

#### AAOIFI FAS #9: Musharakah Financing
**Implementation**: SCS-5 (Disclosure Registry)

**Key Requirements**:
1. **Partnership Accounts**:
   - Each partner's capital contribution
   - Profit-sharing ratios
   - Loss-sharing ratios (must equal capital ratios)
   - Distributions to partners

2. **Disclosure Requirements**:
   - Nature of Musharakah
   - Terms and conditions
   - Profit and loss allocation
   - Partner responsibilities

#### AAOIFI FAS #27: Investment Accounts
**Implementation**: SCS-3 (Vault Engine)

**Key Requirements**:
1. **Investment Account Types**:
   - Unrestricted investment accounts
   - Restricted investment accounts
   - Special investment accounts

2. **Valuation**:
   - Net Asset Value (NAV) calculation
   - Epoch-based accounting
   - Fair value measurement

3. **Disclosure Requirements**:
   - Investment policies
   - Risk factors
   - Performance metrics
   - Fee structure

## Prohibited Elements (Muharramat)

### 1. Capital Guarantee Prohibition

**AAOIFI Rule**: Cannot guarantee return of principal or any specific return

**SCS Implementation**:
```solidity
// ❌ PROHIBITED - Cannot implement:
function guaranteeCapital() { ... }
function guaranteePrincipal() { ... }
function guaranteeMinimumReturn() { ... }
```

**Enforcement**: SCS-4 validates all deployments have `expectedReturn = 0`

### 2. Riba (Interest) Prohibition

**AAOIFI Rule**: No time-based returns or principal-indexed returns

**Prohibited Structures**:
```solidity
// ❌ PROHIBITED:
profit = principal * rate * time;  // Time-based
profit = principal * fixedRate;    // Principal-indexed
if (timePeriod elapsed) pay(guaranteedAmount);  // Periodic guaranteed
```

**SCS Implementation**: No fixed rates, no time-based calculations, profit based on actual performance

### 3. Gharar (Excessive Uncertainty) Prohibition

**AAOIFI Rule**: Contract terms must be clear and determinable

**Requirements**:
```solidity
// ✅ REQUIRED:
uint256 profitShareBps = 7000;  // Exact percentage (70%)
uint256 duration = 90 days;     // Fixed or determinable period

// ❌ PROHIBITED:
string profitShare = "reasonable amount";  // Vague
string duration = "until success";         // Indeterminate
```

### 4. Prohibited Sectors

**AAOIFI Rule**: Cannot invest in prohibited (haram) activities

**Common Prohibited Sectors**:
- Conventional banks/financial institutions
- Alcohol production/sale
- Pork products
- Gambling/casinos/betting
- Adult entertainment
- Weapons (non-defense)
- Conventional insurance

**SCS Implementation**: SCS-5 maintains on-chain prohibited assets registry

### 5. Financial Ratio Tests

**AAOIFI Rule**: For corporate investments, must meet financial purity thresholds

**Thresholds**:
```solidity
uint256 maxDebtRatio = 30;   // Interest-bearing debt / Total assets < 30%
uint256 maxIncomeRatio = 5;  // Interest income / Total income < 5%
```

**SCS Implementation**: SCS-5 provides `checkFinancialRatios()` function

## Compliance Validation Flow

### 1. Contract Deployment
```
Developer → Deploy Contract → Register with SCS-4 → SSB Approval (SCS-5)
```

### 2. Investment Strategy
```
Manager → Propose Strategy → SSB Review (SCS-5) → Multi-sig Approval → Execute
```

### 3. Capital Deployment
```
Manager → Deploy Capital → SCS-4 Validation → Prohibited Assets Check (SCS-5) → Execute
```

### 4. Profit Distribution
```
Calculate Profit → Validate Ratios (SCS-4) → Distribute per Agreement → Record (SCS-5)
```

### 5. Loss Allocation
```
Calculate Loss → Validate Proportionality (SCS-4) → Allocate → Record (SCS-5)
```

## Integration Checklist

For protocols integrating SCS:

- [ ] Deploy SCS-4 Enforcement Layer
- [ ] Deploy SCS-5 Governance with SSB members
- [ ] Register all SCS contracts with enforcement layer
- [ ] Configure prohibited assets list
- [ ] Set up SSB multi-signature wallet
- [ ] Implement disclosure registry
- [ ] Configure financial ratio thresholds
- [ ] Test all validation flows
- [ ] Obtain SSB approval for strategies
- [ ] Document all AAOIFI compliance measures

## Audit Requirements

Before production deployment:

1. **Technical Audit**:
   - Smart contract security audit
   - Gas optimization review
   - Upgradeability assessment

2. **Sharia Audit**:
   - Independent Sharia scholar review
   - SSB certification
   - AAOIFI compliance verification

3. **Operational Audit**:
   - Governance procedures
   - Disclosure mechanisms
   - Monitoring systems

## Ongoing Compliance

### Monitoring
- Regular SSB reviews
- Quarterly compliance reports
- Continuous prohibited assets screening
- Financial ratio monitoring

### Reporting
- Monthly performance reports
- Quarterly Sharia compliance certificates
- Annual audited financial statements
- On-chain disclosure updates

### Governance
- SSB meetings (minimum quarterly)
- Strategy approval process
- Incident response procedures
- Compliance violation handling

## Resources

### Official AAOIFI Resources
- [AAOIFI Official Website](https://www.aaoifi.org/)
- AAOIFI Standards Library (subscription required)
- AAOIFI Sharia Standards (English translation)
- AAOIFI Governance Standards
- AAOIFI Accounting Standards (FAS)

### SCS Documentation
- [SCS-1: Mudarabah Specification](./SCS-1-Mudarabah.md)
- [SCS-2: Musharakah Specification](./SCS-2-Musharakah.md)
- [SCS-3: Vault Engine Specification](./SCS-3-Vault.md)
- [SCS-4: Enforcement Layer](./SCS-4-Enforcement.md)
- [SCS-5: AAOIFI Governance](./SCS-5-Governance.md)

### Islamic Finance References
- Islamic Financial Services Board (IFSB)
- International Islamic Financial Market (IIFM)
- Islamic Finance News (IFN)

## Disclaimer

This implementation provides technical infrastructure for AAOIFI compliance. Users must:

1. Conduct independent Sharia compliance review
2. Obtain qualified Sharia Supervisory Board approval
3. Complete security audits before production deployment
4. Ensure compliance with local regulations
5. Maintain ongoing monitoring and reporting

The SCS project does not provide Sharia advisory services. Consult qualified Islamic finance scholars for Sharia rulings.
