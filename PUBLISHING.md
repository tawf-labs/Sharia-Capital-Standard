# Publishing Guide

This guide is for maintainers who want to publish new versions of Sharia Capital Standard.

## Prerequisites

- Write access to GitHub repository
- npm account with access to `@sharia-capital` organization
- Foundry installed
- All tests passing

## Pre-Release Checklist

- [ ] All tests pass: `forge test`
- [ ] Code formatted: `forge fmt`
- [ ] Documentation updated
- [ ] CHANGELOG.md updated with changes
- [ ] Version bumped in `package.json`
- [ ] No uncommitted changes

## Publishing Workflow

### 1. Version Bump

Update version in `package.json`:
```json
{
  "version": "0.2.0"
}
```

### 2. Test Locally

#### Test with npm pack
```bash
# Build and create tarball
./test-npm-pack.sh

# Verify package contents
tar -tzf sharia-capital-standard-*.tgz

# Test installation
mkdir test-install && cd test-install
npm init -y
npm install ../sharia-capital-standard-*.tgz
cd ..
rm -rf test-install
```

#### Test with Verdaccio (optional but recommended)
```bash
# Terminal 1: Start Verdaccio
./test-verdaccio.sh

# Terminal 2: Publish to local registry
npm adduser --registry http://localhost:4873
npm publish --registry http://localhost:4873

# Test installation
mkdir test-verdaccio && cd test-verdaccio
npm init -y
npm install @sharia-capital/standard --registry http://localhost:4873
cd ..
rm -rf test-verdaccio
```

### 3. Commit and Tag

```bash
# Commit version bump
git add package.json CHANGELOG.md
git commit -m "chore: bump version to 0.2.0"

# Create git tag
git tag v0.2.0

# Push commits and tags
git push origin main
git push origin v0.2.0
```

### 4. Publish to npm

```bash
# Login to npm (first time only)
npm login

# Publish to npm registry
npm publish --access public

# Verify publication
npm view @sharia-capital/standard
```

### 5. Create GitHub Release

1. Go to https://github.com/tawf-labs/Sharia-Capital-Standard/releases
2. Click "Draft a new release"
3. Select tag: `v0.2.0`
4. Release title: `v0.2.0`
5. Description: Copy from CHANGELOG.md
6. Publish release

## Foundry Distribution

Foundry users automatically get updates via git tags. No additional steps needed!

Users install with:
```bash
forge install tawf-labs/Sharia-Capital-Standard@v0.2.0
```

## Post-Release Verification

### Verify npm package
```bash
# Check package info
npm view @sharia-capital/standard

# Test installation
mkdir verify-npm && cd verify-npm
npm init -y
npm install @sharia-capital/standard
ls node_modules/@sharia-capital/standard
cd .. && rm -rf verify-npm
```

### Verify Foundry installation
```bash
# Test forge install
mkdir verify-foundry && cd verify-foundry
forge init
forge install tawf-labs/Sharia-Capital-Standard@v0.2.0
ls lib/Sharia-Capital-Standard
cd .. && rm -rf verify-foundry
```

## Troubleshooting

### npm publish fails with 403
- Ensure you're logged in: `npm whoami`
- Verify organization access: `npm org ls @sharia-capital`
- Check package name isn't taken: `npm view @sharia-capital/standard`

### Package size too large
- Check `.npmignore` is excluding test files
- Verify with: `npm pack --dry-run`
- Target size: < 5MB

### Foundry users can't install
- Verify tag exists: `git tag -l`
- Ensure tag is pushed: `git push origin v0.2.0`
- Check GitHub releases page

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Breaking changes to contract interfaces
- **MINOR** (0.2.0): New features, backward compatible
- **PATCH** (0.1.1): Bug fixes, backward compatible

## Rollback Procedure

If a release has critical issues:

### npm
```bash
# Deprecate the version
npm deprecate @sharia-capital/standard@0.2.0 "Critical bug, use 0.1.0"

# Or unpublish (within 72 hours)
npm unpublish @sharia-capital/standard@0.2.0
```

### Git/Foundry
```bash
# Delete tag locally and remotely
git tag -d v0.2.0
git push origin :refs/tags/v0.2.0

# Delete GitHub release manually
```

## Automation (Future)

Consider setting up:
- GitHub Actions for automated publishing
- Automated changelog generation
- Automated version bumping
- Release notes generation

## Support

For questions about publishing:
- Open an issue: https://github.com/tawf-labs/Sharia-Capital-Standard/issues
- Contact maintainers
