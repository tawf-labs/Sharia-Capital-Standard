# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Dual distribution support (npm + Foundry)
- npm package with contracts and compiled ABIs
- Clean import paths via package exports
- Example projects for Foundry and Hardhat integration
- Publishing guide for maintainers
- Local testing scripts (npm pack + Verdaccio)

### Changed
- Updated README with installation instructions for both npm and Foundry
- Enhanced package.json with repository info and exports mapping

## [0.1.0] - 2026-02-23

### Added
- SCS-1: Mudarabah implementation (manager-investor profit-sharing)
- SCS-2: Musharakah implementation (joint venture capital)
- SCS-3: Vault Engine with ERC-4626 compliance
- SCS-4: Non-Guaranteed Return Enforcement Layer
- SCS-5: AAOIFI Governance & Compliance
- Comprehensive test suite (82 tests, 100% coverage)
- Full documentation for all standards
- AAOIFI compliance guide
- Integration guide
- Security analysis

### Security
- ReentrancyGuard protection on all state-changing functions
- Role-based access control
- Safe ERC20 transfers
- Input validation
- Invariant testing

[Unreleased]: https://github.com/tawf-labs/Sharia-Capital-Standard/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/tawf-labs/Sharia-Capital-Standard/releases/tag/v0.1.0
