# Hardhat Example - Using SCS via npm

This example demonstrates how to use Sharia Capital Standard in a Hardhat project.

## Installation

```bash
# Install SCS from npm
npm install @sharia-capital/standard

# Install Hardhat dependencies
npm install
```

## Usage

The example contract `MyHardhatStrategy.sol` shows how to:
- Import SCS contracts from npm package
- Use both clean and direct import paths
- Interact with MudarabahPool

## Import Styles

### Clean imports (recommended)
```solidity
import "@sharia-capital/standard/SCS1/MudarabahPool.sol";
import "@sharia-capital/standard/SCS2/MusharakahPool.sol";
import "@sharia-capital/standard/interfaces/ISCS1.sol";
```

### Direct path imports (backward compatible)
```solidity
import "@sharia-capital/standard/evm/src/SCS1/MudarabahPool.sol";
import "@sharia-capital/standard/evm/src/SCS2/MusharakahPool.sol";
```

## Compile

```bash
npx hardhat compile
```

## Access ABIs

ABIs are available in the package:
```javascript
const MudarabahPoolABI = require('@sharia-capital/standard/evm/out/MudarabahPool.sol/MudarabahPool.json');
```
