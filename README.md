# Sharia Capital Standard (SCS)

**Open infrastructure-grade risk-sharing capital formation primitive for EVM & SVM networks**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.26-blue)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://getfoundry.sh/)
[![npm version](https://img.shields.io/npm/v/@tawf-labs/sharia-capital-standard.svg)](https://www.npmjs.com/package/@tawf-labs/sharia-capital-standard)

## Overview

SCS provides production-ready smart contract implementations for Sharia-compliant capital formation, based on AAOIFI standards for:

- **SCS-1**: Mudarabah (manager-investor profit-sharing)
- **SCS-2**: Musharakah (joint venture capital)
- **SCS-3**: Profit-Sharing Vault Engine (NAV calculation, epochs)
- **SCS-4**: Non-Guaranteed Return Enforcement Layer
- **SCS-5**: Sharia Governance & Compliance

> **Important Notice**: This is the **TAWF Sharia Standard**, an open-source implementation based on AAOIFI standards. This framework is **not officially approved or endorsed by AAOIFI**. It is designed as a reference implementation inspired by AAOIFI principles for blockchain-based Islamic finance. Users must obtain independent Sharia Supervisory Board approval before production use.

## AAOIFI Standards Reference

This project is based on standards from the [Accounting and Auditing Organization for Islamic Financial Institutions](https://aaoifi.com/?lang=en):

- **[Sharia Standard #8](https://aaoifi.com/product/shari-a-standards/?lang=en)**: Mudarabah (profit-sharing partnership)
- **[Sharia Standard #12](https://aaoifi.com/product/shari-a-standards/?lang=en)**: Musharakah (joint venture)
- **[Sharia Standard #17](https://aaoifi.com/product/shari-a-standards/?lang=en)**: Investment Agencies
- **[Governance Standard #3](https://aaoifi.com/product/governance-standards-for-islamic-financial-institutions/?lang=en)**: Internal Sharia Review
- **[Financial Accounting Standards](https://aaoifi.com/product/financial-accounting-standards/?lang=en)**: FAS #4, #9, #27

## Project Structure

```
Sharia-Capital-Standard/
├── evm/                    # EVM implementation (Solidity)
│   ├── src/
│   │   ├── interfaces/     # Core SCS interfaces
│   │   ├── SCS1/          # Mudarabah ✅
│   │   ├── SCS2/          # Musharakah ✅
│   │   ├── SCS3/          # Vault Engine ✅
│   │   ├── SCS4/          # Enforcement Layer ✅
│   │   ├── SCS5/          # AAOIFI Governance ✅
│   │   └── libraries/     # Shared libraries
│   └── test/              # Comprehensive test suite
└── solana/                # SVM implementation (Anchor)
    └── programs/
```

## Installation

### For Foundry Projects (Recommended)

Install as a Foundry dependency:

```bash
forge install tawf-labs/Sharia-Capital-Standard
```

Add to your `remappings.txt`:
```
@sharia-capital/=lib/Sharia-Capital-Standard/evm/src/
```

Import in your contracts:
```solidity
import "@sharia-capital/SCS1/MudarabahPool.sol";
import "@sharia-capital/SCS2/MusharakahPool.sol";
import "@sharia-capital/SCS3/VaultEngine.sol";
import "@sharia-capital/SCS4/SCSEnforcement.sol";
import "@sharia-capital/SCS5/ShariaGovernance.sol";
```

### For Hardhat/npm Projects

Install via npm:

```bash
npm install @tawf-labs/sharia-capital-standard
# or
yarn add @tawf-labs/sharia-capital-standard
```

Import in your contracts (clean style):
```solidity
import "@tawf-labs/sharia-capital-standard/SCS1/MudarabahPool.sol";
import "@tawf-labs/sharia-capital-standard/interfaces/ISCS1.sol";
```

Or use direct paths:
```solidity
import "@tawf-labs/sharia-capital-standard/evm/src/SCS1/MudarabahPool.sol";
```

Access ABIs in JavaScript/TypeScript:
```javascript
const MudarabahPoolABI = require('@tawf-labs/sharia-capital-standard/evm/out/MudarabahPool.sol/MudarabahPool.json');
```

### For Development

Clone the repository to contribute or run tests:

```bash
git clone https://github.com/tawf-labs/Sharia-Capital-Standard.git
cd Sharia-Capital-Standard

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

# Run tests with gas report
forge test --gas-report
```

### Usage Example

```solidity
// Create Mudarabah pool
MudarabahFactory factory = new MudarabahFactory(enforcementAddress);

address pool = factory.createPool(
    usdcAddress,
    managerAddress,
    capitalProviderAddress,
    2000, // 20% manager share (basis points)
    8000, // 80% provider share (basis points)
    "USDC Mudarabah Pool",
    "MDP-USDC"
);

// Deposit capital
MudarabahPool mudarabah = MudarabahPool(pool);
usdc.approve(pool, 1000e6);
mudarabah.deposit(1000e6);

// Deploy to strategy
mudarabah.deployCapital(strategyAddress, 500e6);
```

## Core Concepts

### Mudarabah (SCS-1)
Manager-investor profit-sharing model where:
- Capital provider (Rabb al-Mal) provides capital
- Manager (Mudarib) manages investments
- Profits shared by pre-agreed ratio
- Losses borne by capital provider (except misconduct)

### Musharakah (SCS-2)
Joint venture model where:
- All partners contribute capital
- Profit ratio can differ from capital ratio
- Loss ratio MUST equal capital ratio (AAOIFI requirement)

### Vault Engine (SCS-3)
ERC-4626 compliant vault with:
- Epoch-based accounting
- NAV calculation
- Strategy management

### Enforcement Layer (SCS-4)
Ensures Sharia compliance by:
- Prohibiting guaranteed returns
- Preventing fixed-yield structures
- Validating profit-sharing ratios

### Sharia Governance (SCS-5)
Based on AAOIFI Governance Standard #3:
- Sharia Supervisory Board (SSB) oversight
- Multi-signature approval for investments
- Prohibited asset screening
- Financial ratio validation

## Documentation

- [SCS-1: Mudarabah Specification](docs/SCS-1-Mudarabah.md)
- [SCS-2: Musharakah Specification](docs/SCS-2-Musharakah.md)
- [SCS-3: Vault Engine Specification](docs/SCS-3-Vault.md)
- [SCS-4: Enforcement Layer](docs/SCS-4-Enforcement.md)
- [SCS-5: AAOIFI Governance](docs/SCS-5-Governance.md)
- [AAOIFI Compliance Guide](docs/AAOIFI-Compliance.md)
- [Integration Guide](docs/integration.md)

## Security

- Comprehensive test coverage (100%)
- Fuzz testing (256+ iterations)
- Invariant testing
- ReentrancyGuard protection
- Role-based access control
- Static analysis via [Aderyn](https://github.com/Cyfrin/aderyn) in CI
- External audit recommended before production use

### Security Analysis

This project uses [Aderyn](https://github.com/Cyfrin/aderyn), a Rust-based Solidity static analyzer by Cyfrin, to automatically detect potential vulnerabilities in the codebase.

**Automated CI Checks:**
- Aderyn runs automatically on every push and pull request
- Builds fail on high-severity findings
- Analysis reports are available in GitHub Actions logs

**Local Analysis (Optional):**

Developers can run Aderyn locally for immediate feedback:

```bash
# Install Aderyn (requires Rust)
cargo install aderyn

# Run analysis on the project
aderyn .

# View the generated report
cat report.md
```

For more information, see the [Aderyn documentation](https://cyfrin.gitbook.io/cyfrin-docs).

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Disclaimer

This is reference implementation software. Users must:
1. Conduct independent Sharia compliance review
2. Obtain qualified Sharia Supervisory Board approval
3. Complete security audits before production deployment
4. Ensure compliance with local regulations

## References

- [AAOIFI Official Website](https://aaoifi.com/?lang=en)
- [AAOIFI Sharia Standards](https://aaoifi.com/product/shari-a-standards/?lang=en)
- [AAOIFI Governance Standards](https://aaoifi.com/product/governance-standards-for-islamic-financial-institutions/?lang=en)
- [AAOIFI Financial Accounting Standards](https://aaoifi.com/product/financial-accounting-standards/?lang=en)
- [ERC-4626 Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

## Contact

For questions or collaboration: [Create an issue](https://github.com/yourusername/Sharia-Capital-Standard/issues)
