# Integration Guide
### Sharia Capital Standard by TAWF Labs

## Overview

> **Important Notice**: This is part of the **TAWF Sharia Standard**, based on AAOIFI standards but **not officially approved or endorsed by AAOIFI**. Users must obtain independent Sharia Supervisory Board approval before production use.

This guide demonstrates how to integrate all Sharia Capital Standard (SCS) components to build complete, Sharia-compliant (based on AAOIFI standards) DeFi protocols.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   SCS-5 Governance                      │
│              (Sharia Supervisory Board)                 │
│  ┌──────────────────────────────────────────────────┐  │
│  │  • Multi-sig approval                            │  │
│  │  • Asset screening                               │  │
│  │  • Financial ratio validation                    │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │ Oversight
        ┌────────────┼────────────┐
        │            │            │
   ┌────▼────┐  ┌───▼────┐  ┌───▼────┐
   │  SCS-1  │  │ SCS-2  │  │ SCS-3  │
   │Mudarabah│  │Mushar. │  │ Vault  │
   └────┬────┘  └───┬────┘  └───┬────┘
        │           │            │
        └───────────┼────────────┘
                    │
              ┌─────▼─────┐
              │   SCS-4   │
              │Enforcement│
              └───────────┘
```

## Integration Patterns

### Pattern 1: Governed Mudarabah Pool

Complete implementation with SSB oversight.

```solidity
// 1. Deploy infrastructure
SCSEnforcement enforcement = new SCSEnforcement();
ShariaBoard board = new ShariaBoard(ssbMembers, 2);
ShariaGovernance governance = new ShariaGovernance(address(board));

// 2. Screen assets
governance.screenAsset(usdcAddress, true, "Stablecoin - Compliant");

// 3. Create Mudarabah pool
MudarabahFactory factory = new MudarabahFactory(address(enforcement));
address pool = factory.createPool(
    usdcAddress,
    manager,
    provider,
    2000, // 20% manager
    8000, // 80% provider
    "Governed Mudarabah",
    "GMD"
);

// 4. SSB approves strategy
bytes32 strategyHash = keccak256(abi.encodePacked(strategyAddress));
board.approveStrategy(strategyHash); // Requires quorum

// 5. Deploy capital
mudarabah.deployCapital(strategyAddress, amount);
```

### Pattern 2: Multi-Strategy Vault with Governance

ERC-4626 vault with SSB-approved strategies.

```solidity
// 1. Deploy vault
VaultEngine vault = new VaultEngine(
    usdcAddress,
    address(enforcement),
    "Governed Vault",
    "gVault"
);

// 2. SSB approves strategies
board.approveStrategy(keccak256(abi.encodePacked(strategy1)));
board.approveStrategy(keccak256(abi.encodePacked(strategy2)));

// 3. Add strategies
vault.addStrategy(strategy1, 5000); // 50%
vault.addStrategy(strategy2, 3000); // 30%

// 4. Users deposit (ERC-4626)
vault.deposit(amount, user);

// 5. Deploy to strategies
vault.deployToStrategy(strategy1, amount1);
vault.deployToStrategy(strategy2, amount2);

// 6. Epoch management
vault.startNewEpoch(); // Calculates performance fees
```

### Pattern 3: Musharakah with Compliance

Joint venture with financial ratio validation.

```solidity
// 1. Create Musharakah pool
MusharakahFactory factory = new MusharakahFactory(address(enforcement));
address pool = factory.createPool(
    usdcAddress,
    partners,      // [partner1, partner2, partner3]
    profitShares,  // [5000, 3000, 2000] = 50%, 30%, 20%
    "Joint Venture",
    "JV"
);

// 2. Partners contribute
musharakah.contributeCapital(amount1); // Partner 1
musharakah.contributeCapital(amount2); // Partner 2

// 3. Validate financial ratios
bool compliant = governance.validateFinancialRatios(
    totalAssets,
    totalDebt,
    interestIncome
);

// 4. Deploy if compliant
if (compliant) {
    musharakah.deployCapital(strategy, amount);
}
```

## Complete Example: Governed DeFi Protocol

### Step 1: Deploy Core Infrastructure

```solidity
// Deploy enforcement layer
SCSEnforcement enforcement = new SCSEnforcement();

// Deploy Sharia Board (3 scholars, 2 required)
address[] memory scholars = new address[](3);
scholars[0] = scholar1;
scholars[1] = scholar2;
scholars[2] = scholar3;
ShariaBoard board = new ShariaBoard(scholars, 2);

// Deploy governance
ShariaGovernance governance = new ShariaGovernance(address(board));
governance.transferOwnership(address(board));
```

### Step 2: Screen Assets

```solidity
// Screen compliant assets
governance.screenAsset(usdcAddress, true, "Stablecoin");
governance.screenAsset(daiAddress, true, "Stablecoin");

// Prohibit non-compliant assets
governance.prohibitAsset(wethAddress); // Interest-bearing
```

### Step 3: Deploy Protocols

```solidity
// Deploy Mudarabah factory
MudarabahFactory mudarabahFactory = new MudarabahFactory(address(enforcement));

// Deploy Musharakah factory
MusharakahFactory musharakahFactory = new MusharakahFactory(address(enforcement));

// Deploy Vault
VaultEngine vault = new VaultEngine(
    usdcAddress,
    address(enforcement),
    "Islamic Vault",
    "iVault"
);
```

### Step 4: Create Pools

```solidity
// Create Mudarabah pool
address mudarabahPool = mudarabahFactory.createPool(
    usdcAddress,
    manager,
    provider,
    2000,
    8000,
    "USDC Mudarabah",
    "mUSDC"
);

// Create Musharakah pool
address musharakahPool = musharakahFactory.createPool(
    daiAddress,
    partners,
    profitShares,
    "DAI Joint Venture",
    "jDAI"
);
```

### Step 5: SSB Approval Workflow

```solidity
// Submit proposal for strategy approval
bytes32 proposalId = board.submitProposal(
    "Approve Aave V3 USDC strategy",
    address(governance),
    abi.encodeWithSignature("permitAsset(address)", aaveStrategy),
    ShariaBoard.ProposalType.INVESTMENT
);

// Scholars approve (requires 2 of 3)
board.approveProposal(proposalId); // Scholar 1
board.approveProposal(proposalId); // Scholar 2

// Execute proposal
board.executeProposal(proposalId);
```

### Step 6: Operations

```solidity
// Provider deposits to Mudarabah
mudarabah.deposit(1000e6);

// Manager deploys to approved strategy
mudarabah.deployCapital(aaveStrategy, 500e6);

// Partners contribute to Musharakah
musharakah.contributeCapital(500e6); // Partner 1
musharakah.contributeCapital(300e6); // Partner 2

// Users deposit to Vault (ERC-4626)
vault.deposit(2000e6, user);
```

## Best Practices

### 1. Always Screen Assets First

```solidity
// Before any deployment
require(governance.validateAsset(asset), "Asset not screened");
```

### 2. Validate Financial Ratios

```solidity
// Before major operations
bool compliant = governance.validateFinancialRatios(
    totalAssets,
    totalDebt,
    interestIncome
);
require(compliant, "Ratios exceed AAOIFI limits");
```

### 3. Use SSB Approval for Strategies

```solidity
// Before deploying to new strategy
bytes32 strategyHash = keccak256(abi.encodePacked(strategy));
require(board.isStrategyApproved(strategyHash), "Strategy not approved");
```

### 4. Regular Compliance Checks

```solidity
// Periodic validation
function checkCompliance() external view returns (bool) {
    // Check asset compliance
    if (!governance.validateAsset(asset)) return false;
    
    // Check financial ratios
    if (!governance.validateFinancialRatios(...)) return false;
    
    // Check strategy approval
    if (!board.isStrategyApproved(strategyHash)) return false;
    
    return true;
}
```

## Gas Optimization Tips

1. **Batch Operations**: Submit multiple proposals in one transaction
2. **Cache Results**: Store SSB approval results
3. **Minimize Storage**: Use events for historical data
4. **Efficient Loops**: Limit partner/member counts

## Security Considerations

1. **Multi-Sig**: Always use SSB quorum for critical decisions
2. **Timelock**: Consider adding delays for proposal execution
3. **Emergency Pause**: Implement pause mechanisms
4. **Audit Trail**: Emit events for all governance actions
5. **Access Control**: Strict role-based permissions

## Testing Integration

```solidity
function testFullIntegration() public {
    // 1. Setup
    deployInfrastructure();
    
    // 2. Screen assets
    screenAssets();
    
    // 3. Create pools
    createPools();
    
    // 4. SSB approval
    approveStrategies();
    
    // 5. Operations
    executeOperations();
    
    // 6. Validate
    assertCompliance();
}
```

## Deployment Checklist

- [ ] Deploy SCSEnforcement
- [ ] Deploy ShariaBoard with SSB members
- [ ] Deploy ShariaGovernance
- [ ] Screen all assets
- [ ] Deploy factories (Mudarabah, Musharakah)
- [ ] Deploy VaultEngine
- [ ] Configure financial ratio limits
- [ ] Test SSB approval workflow
- [ ] Verify all integrations
- [ ] Security audit
- [ ] SSB final approval

## References

- [SCS-1 Mudarabah](./SCS-1-Mudarabah.md)
- [SCS-2 Musharakah](./SCS-2-Musharakah.md)
- [SCS-3 Vault Engine](./SCS-3-Vault.md)
- [SCS-4 Enforcement](./SCS-4-Enforcement.md)
- [SCS-5 Governance](./SCS-5-Governance.md)
