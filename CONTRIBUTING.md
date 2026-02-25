# Contributing to Sharia Capital Standard

## Code of Conduct

Be respectful, inclusive, and professional.

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development Setup

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone and setup
git clone https://github.com/yourusername/Sharia-Capital-Standard.git
cd Sharia-Capital-Standard
forge install
forge build
forge test
```

## Coding Standards

- Solidity 0.8.26+
- Follow OpenZeppelin patterns
- 95%+ test coverage required
- NatSpec documentation for all public functions
- Gas optimization where possible

## Testing Requirements

All PRs must include:
- Unit tests for new functionality
- Integration tests for cross-contract interactions
- Fuzz tests for mathematical operations
- Gas benchmarks

## Sharia Compliance (Based on AAOIFI Standards)

All changes must maintain Sharia compliance based on AAOIFI standards:
- No guaranteed returns
- No fixed-yield structures
- Proper loss allocation (Musharakah)
- SSB governance requirements

## Pull Request Process

1. Update documentation
2. Add tests (95%+ coverage)
3. Run `forge fmt` for formatting
4. Ensure all tests pass
5. Update CHANGELOG.md
6. Request review from maintainers

## Questions?

Open an issue for discussion before major changes.
