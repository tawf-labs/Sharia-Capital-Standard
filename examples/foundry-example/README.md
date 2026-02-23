# Foundry Example - Using SCS via forge install

This example demonstrates how to use Sharia Capital Standard in a Foundry project.

## Installation

```bash
# Install SCS as a Foundry dependency
forge install tawf-labs/Sharia-Capital-Standard

# Build
forge build
```

## Usage

The example contract `MyMudarabahStrategy.sol` shows how to:
- Import SCS contracts using remappings
- Interact with MudarabahPool
- Use SCSEnforcement

## Remappings

Add to your `remappings.txt`:
```
@sharia-capital/=lib/Sharia-Capital-Standard/evm/src/
```

## Import Examples

```solidity
// Clean imports
import "@sharia-capital/SCS1/MudarabahPool.sol";
import "@sharia-capital/SCS2/MusharakahPool.sol";
import "@sharia-capital/SCS3/VaultEngine.sol";
import "@sharia-capital/SCS4/SCSEnforcement.sol";
import "@sharia-capital/SCS5/AAOIFIGovernance.sol";
```
