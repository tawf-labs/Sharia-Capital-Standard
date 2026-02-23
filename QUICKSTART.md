# Quick Start Guide

## Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Git installed
- Basic understanding of Solidity and Islamic finance concepts

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/Sharia-Capital-Standard.git
cd Sharia-Capital-Standard
```

### 2. Install Dependencies

```bash
forge install
```

This will install:
- OpenZeppelin Contracts v5.1.0
- Forge Standard Library v1.15.0

### 3. Build Contracts

```bash
forge build
```

Expected output:
```
Compiling 12 files with Solc 0.8.26
Solc 0.8.26 finished in 64.84ms
Compiler run successful!
```

### 4. Run Tests

```bash
forge test
```

Expected output:
```
Ran 1 test suite: 13 tests passed, 0 failed, 0 skipped
```

### 5. Run Tests with Verbosity

```bash
forge test -vvv
```

### 6. Generate Gas Report

```bash
forge test --gas-report
```

### 7. Check Code Coverage

```bash
forge coverage
```

## Project Structure

```
Sharia-Capital-Standard/
├── evm/src/
│   ├── interfaces/        # Core SCS interfaces
│   │   ├── ISCS1.sol      # Mudarabah interface
│   │   ├── ISCS2.sol      # Musharakah interface
│   │   ├── ISCS3.sol      # Vault Engine interface
│   │   ├── ISCS4.sol      # Enforcement interface
│   │   └── ISCS5.sol      # Governance interface
│   └── SCS4/
│       └── SCSEnforcement.sol  # Enforcement implementation
├── evm/test/
│   └── unit/
│       └── SCSEnforcement.t.sol  # Tests
└── docs/                  # Documentation
```

## Basic Usage

### Using the Enforcement Layer

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SCSEnforcement} from "./SCS4/SCSEnforcement.sol";
import {ISCS4} from "./interfaces/ISCS4.sol";

contract MyMudarabahPool {
    SCSEnforcement public enforcement;
    
    constructor(address _enforcement) {
        enforcement = SCSEnforcement(_enforcement);
    }
    
    function deployCapital(uint256 amount) external {
        // Validate deployment (no guaranteed returns)
        ISCS4.ValidationResult memory result = 
            enforcement.validateDeployment(amount, 0);
        
        require(result.isCompliant, result.reason);
        
        // Proceed with deployment
        _deploy(amount);
    }
    
    function _deploy(uint256 amount) internal {
        // Your deployment logic
    }
}
```

### Validating Profit Ratios

```solidity
// 70% to capital provider, 30% to manager
ISCS4.ValidationResult memory result = 
    enforcement.validateProfitRatio(7000, 3000);

require(result.isCompliant, result.reason);
```

### Validating Loss Allocation (Musharakah)

```solidity
// Partner with 30% capital must bear 30% of loss
uint256 partnerCapital = 300 ether;
uint256 totalCapital = 1000 ether;
uint256 totalLoss = 100 ether;
uint256 partnerLoss = 30 ether;

ISCS4.ValidationResult memory result = 
    enforcement.validateLossAllocation(
        partnerCapital,
        totalCapital,
        partnerLoss,
        totalLoss
    );

require(result.isCompliant, result.reason);
```

## Running Specific Tests

### Run a specific test file

```bash
forge test --match-path evm/test/unit/SCSEnforcement.t.sol
```

### Run a specific test function

```bash
forge test --match-test test_ValidateDeployment_Success
```

### Run with gas reporting

```bash
forge test --match-contract SCSEnforcementTest --gas-report
```

## Development Workflow

### 1. Create a new branch

```bash
git checkout -b feature/my-feature
```

### 2. Make changes

Edit contracts in `evm/src/`

### 3. Write tests

Add tests in `evm/test/`

### 4. Run tests

```bash
forge test
```

### 5. Format code

```bash
forge fmt
```

### 6. Commit changes

```bash
git add .
git commit -m "feat: add my feature"
```

### 7. Push and create PR

```bash
git push origin feature/my-feature
```

## Common Commands

| Command | Description |
|---------|-------------|
| `forge build` | Compile contracts |
| `forge test` | Run all tests |
| `forge test -vvv` | Run tests with verbose output |
| `forge test --gas-report` | Generate gas usage report |
| `forge coverage` | Generate coverage report |
| `forge fmt` | Format Solidity code |
| `forge clean` | Clean build artifacts |
| `forge snapshot` | Create gas snapshot |

## Troubleshooting

### Build fails with "file not found"

Make sure you've installed dependencies:
```bash
forge install
```

### Tests fail with import errors

Check your `remappings.txt`:
```
@openzeppelin/=evm/lib/openzeppelin-contracts/
forge-std/=evm/lib/forge-std/src/
```

### Git submodule issues

Update submodules:
```bash
git submodule update --init --recursive
```

## Next Steps

1. **Read Documentation**:
   - [AAOIFI Compliance Guide](docs/AAOIFI-Compliance.md)
   - [SCS-4 Enforcement Layer](docs/SCS-4-Enforcement.md)

2. **Explore Interfaces**:
   - Review `evm/src/interfaces/` for all SCS standards

3. **Contribute**:
   - Check [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
   - Look for open issues on GitHub

4. **Stay Updated**:
   - Watch the repository for updates
   - Join discussions on GitHub

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [AAOIFI Official Website](https://www.aaoifi.org/)

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/Sharia-Capital-Standard/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/Sharia-Capital-Standard/discussions)
- **Security**: See [SECURITY.md](SECURITY.md)

## Gas Benchmarks (Phase 1)

| Function | Gas Cost |
|----------|----------|
| validateDeployment | ~770 gas |
| validateProfitRatio | ~830 gas |
| validateLossAllocation | ~1,075 gas |
| registerContract | ~70,207 gas (first time) |
| deregisterContract | ~28,408 gas |

## License

MIT License - see [LICENSE](LICENSE) for details.
