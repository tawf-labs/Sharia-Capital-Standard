# Quick Reference - Installation & Usage

## Installation

### Foundry
```bash
forge install tawf-labs/Sharia-Capital-Standard
```

Add to `remappings.txt`:
```
@sharia-capital/=lib/Sharia-Capital-Standard/evm/src/
```

### npm/Hardhat
```bash
npm install @tawf-labs/sharia-capital-standard
```

## Import Examples

### Foundry
```solidity
import "@sharia-capital/SCS1/MudarabahPool.sol";
import "@sharia-capital/SCS2/MusharakahPool.sol";
import "@sharia-capital/SCS3/VaultEngine.sol";
import "@sharia-capital/SCS4/SCSEnforcement.sol";
import "@sharia-capital/SCS5/ShariaGovernance.sol";
import "@sharia-capital/interfaces/ISCS1.sol";
```

### Hardhat/npm (Clean)
```solidity
import "@tawf-labs/sharia-capital-standard/SCS1/MudarabahPool.sol";
import "@tawf-labs/sharia-capital-standard/SCS2/MusharakahPool.sol";
import "@tawf-labs/sharia-capital-standard/interfaces/ISCS1.sol";
```

### Hardhat/npm (Direct)
```solidity
import "@tawf-labs/sharia-capital-standard/evm/src/SCS1/MudarabahPool.sol";
```

## Access ABIs (JavaScript)
```javascript
const MudarabahPoolABI = require('@tawf-labs/sharia-capital-standard/evm/out/MudarabahPool.sol/MudarabahPool.json');
const MusharakahPoolABI = require('@tawf-labs/sharia-capital-standard/evm/out/MusharakahPool.sol/MusharakahPool.json');
```

## Basic Usage

### Create Mudarabah Pool
```solidity
MudarabahFactory factory = new MudarabahFactory(enforcementAddress);
address pool = factory.createPool(
    usdcAddress,
    managerAddress,
    providerAddress,
    2000, // 20% manager
    8000, // 80% provider
    "USDC Mudarabah",
    "mUSDC"
);
```

### Create Musharakah Pool
```solidity
MusharakahFactory factory = new MusharakahFactory(enforcementAddress);
address[] memory partners = new address[](2);
partners[0] = partner1;
partners[1] = partner2;

uint256[] memory shares = new uint256[](2);
shares[0] = 6000; // 60%
shares[1] = 4000; // 40%

address pool = factory.createPool(
    daiAddress,
    partners,
    shares,
    "DAI Joint Venture",
    "jDAI"
);
```

### Create Vault
```solidity
VaultEngine vault = new VaultEngine(
    usdcAddress,
    enforcementAddress,
    "Islamic Vault",
    "iVault"
);
```

## Documentation

- [Full README](./README.md)
- [Integration Guide](./docs/integration.md)
- [AAOIFI Compliance](./docs/AAOIFI-Compliance.md)
- [Publishing Guide](./PUBLISHING.md) (for maintainers)
- [Testing Guide](./TESTING-NPM.md) (for maintainers)

## Examples

- [Foundry Example](./examples/foundry-example/)
- [Hardhat Example](./examples/hardhat-example/)

## Links

- **GitHub**: https://github.com/tawf-labs/Sharia-Capital-Standard
- **npm**: https://www.npmjs.com/package/@tawf-labs/sharia-capital-standard
- **Issues**: https://github.com/tawf-labs/Sharia-Capital-Standard/issues
