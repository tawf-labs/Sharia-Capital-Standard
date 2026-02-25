# Release v0.1.4

## 🎨 Branding Enhancements

- **Enhanced TAWF Labs visibility** across all documentation
  - Added "by TAWF Labs" subtitle to main README
  - Added branding headers to all SCS specification documents (SCS-1 through SCS-5)
  - Added branding to integration guide

## 🔄 Refactoring

- **Renamed governance contracts for clarity:**
  - `AAOIFIGovernance.sol` → `ShariaGovernance.sol`
  - `IAAOIFICompliant.sol` → `IShariaCompliant.sol`
- Updated all contract implementations to use new naming
- Updated factory contracts and interfaces
- Updated test files to reflect new naming conventions

## 📦 Package Updates

- Bumped npm package version to 0.1.4
- Published updated contracts to npm registry
- All ABIs and interfaces updated

## 🔗 Links

- **npm Package**: https://www.npmjs.com/package/@tawf-labs/sharia-capital-standard
- **Documentation**: https://github.com/tawf-labs/Sharia-Capital-Standard#readme

## ⚠️ Breaking Changes

If you were importing `AAOIFIGovernance` or `IAAOIFICompliant`, update your imports:

```solidity
// Old
import "@tawf-labs/sharia-capital-standard/SCS5/AAOIFIGovernance.sol";
import "@tawf-labs/sharia-capital-standard/interfaces/IAAOIFICompliant.sol";

// New
import "@tawf-labs/sharia-capital-standard/SCS5/ShariaGovernance.sol";
import "@tawf-labs/sharia-capital-standard/interfaces/IShariaCompliant.sol";
```

## 📝 Full Changelog

**Commits:**
- chore: emphasize TAWF Labs branding and bump version to 0.1.3
- refactor: rename AAOIFIGovernance to ShariaGovernance and update interfaces
- chore: bump version to 0.1.4
