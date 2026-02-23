# Release Notes - v0.1.2

**Release Date:** 2026-02-23  
**Status:** ✅ Published to npm & GitHub

## 🔒 Security Improvements

This release focuses on dramatically improving the package's supply chain security score by eliminating all npm dev dependencies.

### Changes

**Security:**
- ✅ Removed solhint and all npm dev dependencies (113 packages removed)
- ✅ Eliminated `graceful-fs@4.2.10` vulnerability
- ✅ Confirmed 0 npm vulnerabilities
- ✅ Added Aderyn static analysis to CI pipeline
- ✅ Supply Chain Security score improved from 51 to expected 95+

**CI/CD:**
- ✅ Added new `security` job using Cyfrin Aderyn CI Assistant
- ✅ Configured to fail builds on high-severity findings
- ✅ Runs in parallel with existing test/lint/build jobs

**Documentation:**
- ✅ Added Security Analysis section to README
- ✅ Documented Aderyn CI integration
- ✅ Added instructions for optional local Aderyn installation

**Testing:**
- ✅ All 82 tests passing (7 test suites, 0 failures)
- ✅ Contracts compile successfully
- ✅ No breaking changes

## 📦 Package Details

- **Package:** `@tawf-labs/sharia-capital-standard@0.1.2`
- **Size:** 617.4 kB compressed, 3.9 MB unpacked
- **Files:** 95 files
- **Registry:** https://www.npmjs.com/package/@tawf-labs/sharia-capital-standard

## 🚀 Installation

```bash
npm install @tawf-labs/sharia-capital-standard
# or
yarn add @tawf-labs/sharia-capital-standard
# or for Foundry
forge install tawf-labs/Sharia-Capital-Standard
```

## 📊 Metrics Improvement

| Metric | Before (v0.1.1) | After (v0.1.2) |
|--------|-----------------|----------------|
| Supply Chain Security | 51 ⚠️ | Expected 95+ ✅ |
| npm Dependencies | 113 packages | 0 packages 🎉 |
| Vulnerabilities | Multiple | 0 ✅ |
| Vulnerability Score | 100 | 100 ✅ |
| Quality Score | 93 | 93 ✅ |
| Maintenance Score | 86 | 86 ✅ |
| License Score | 100 | 100 ✅ |

## 🔗 Links

- **npm:** https://www.npmjs.com/package/@tawf-labs/sharia-capital-standard
- **GitHub:** https://github.com/tawf-labs/Sharia-Capital-Standard
- **Commit:** 5e14a60

## 🙏 Credits

- [Aderyn](https://github.com/Cyfrin/aderyn) by Cyfrin for modern Rust-based static analysis
- Community feedback on supply chain security concerns

---

**No breaking changes** - This is a drop-in replacement for v0.1.1 with improved security posture.
