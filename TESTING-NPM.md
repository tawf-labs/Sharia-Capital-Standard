# Testing the npm Package Locally

This guide walks you through testing the npm package before publishing to the public registry.

## Quick Test with npm pack

The fastest way to test the package:

```bash
# 1. Build contracts
forge build

# 2. Create package tarball
npm pack

# 3. Check package contents
tar -tzf sharia-capital-standard-0.1.0.tgz | less

# 4. Check package size (should be < 5MB)
ls -lh sharia-capital-standard-0.1.0.tgz
```

## Test Installation

### Test in a Hardhat Project

```bash
# Create test directory
mkdir test-hardhat && cd test-hardhat

# Initialize Hardhat project
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox

# Install your local package
npm install ../sharia-capital-standard-0.1.0.tgz

# Create test contract
cat > contracts/Test.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@sharia-capital/standard/SCS1/MudarabahPool.sol";

contract Test {
    function test() external pure returns (string memory) {
        return "SCS imported successfully!";
    }
}
EOF

# Create hardhat config
cat > hardhat.config.js << 'EOF'
require("@nomicfoundation/hardhat-toolbox");
module.exports = {
  solidity: "0.8.26"
};
EOF

# Compile
npx hardhat compile

# Clean up
cd .. && rm -rf test-hardhat
```

### Test in a Foundry Project

```bash
# Create test directory
mkdir test-foundry && cd test-foundry

# Initialize Foundry project
forge init --no-git

# Install from local tarball (requires extracting first)
mkdir -p lib/@sharia-capital
tar -xzf ../sharia-capital-standard-0.1.0.tgz -C lib/@sharia-capital
mv lib/@sharia-capital/package lib/@sharia-capital/standard

# Add remapping
echo "@sharia-capital/standard/=lib/@sharia-capital/standard/evm/src/" > remappings.txt

# Create test contract
cat > src/Test.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@sharia-capital/standard/SCS1/MudarabahPool.sol";

contract Test {
    function test() external pure returns (string memory) {
        return "SCS imported successfully!";
    }
}
EOF

# Build
forge build

# Clean up
cd .. && rm -rf test-foundry
```

## Full Test with Verdaccio

Verdaccio is a local npm registry that simulates the real npm publishing experience.

### Setup Verdaccio

```bash
# Install Verdaccio globally
npm install -g verdaccio

# Or use npx (no installation needed)
npx verdaccio
```

### Start Verdaccio

```bash
# Terminal 1: Start the registry
verdaccio

# It will start on http://localhost:4873
# Keep this terminal open
```

### Publish to Verdaccio

```bash
# Terminal 2: Configure npm to use local registry
npm set registry http://localhost:4873

# Create a user (use any credentials)
npm adduser --registry http://localhost:4873
# Username: test
# Password: test
# Email: test@test.com

# Build contracts
forge build

# Publish to local registry
npm publish --registry http://localhost:4873

# Verify publication
npm view @sharia-capital/standard --registry http://localhost:4873
```

### Test Installation from Verdaccio

```bash
# Create test project
mkdir test-verdaccio && cd test-verdaccio
npm init -y

# Install from local registry
npm install @sharia-capital/standard --registry http://localhost:4873

# Verify installation
ls node_modules/@sharia-capital/standard

# Check imports work
node -e "console.log(require('@sharia-capital/standard/package.json').version)"

# Clean up
cd .. && rm -rf test-verdaccio
```

### Reset npm Registry

```bash
# After testing, reset to public npm registry
npm set registry https://registry.npmjs.org
```

## Automated Test Script

Use the provided test scripts:

```bash
# Quick test with npm pack
./test-npm-pack.sh

# Full test with Verdaccio (in separate terminal)
./test-verdaccio.sh
```

## What to Verify

### Package Contents
- ✅ Contains `evm/src/**/*.sol` (source contracts)
- ✅ Contains `evm/out/**/*.json` (compiled ABIs)
- ✅ Contains `README.md` and `LICENSE`
- ✅ Does NOT contain test files
- ✅ Does NOT contain docs/ directory
- ✅ Does NOT contain .git/ directory
- ✅ Package size < 5MB

### Import Paths
- ✅ Clean imports work: `@sharia-capital/standard/SCS1/MudarabahPool.sol`
- ✅ Direct imports work: `@sharia-capital/standard/evm/src/SCS1/MudarabahPool.sol`
- ✅ Interface imports work: `@sharia-capital/standard/interfaces/ISCS1.sol`

### ABIs Accessible
- ✅ Can require ABIs: `require('@sharia-capital/standard/evm/out/MudarabahPool.sol/MudarabahPool.json')`
- ✅ ABIs contain correct contract data

### Compilation
- ✅ Contracts compile in Hardhat
- ✅ Contracts compile in Foundry
- ✅ No missing dependencies

## Troubleshooting

### "Cannot find module" errors
- Check remappings are correct
- Verify package is installed in node_modules
- Check import paths match exports in package.json

### Compilation errors
- Ensure Solidity version matches (0.8.26)
- Check OpenZeppelin dependencies are available
- Verify all imports resolve correctly

### Package too large
- Check .npmignore is excluding test files
- Run `npm pack --dry-run` to see what will be included
- Remove unnecessary files from package

### Verdaccio issues
- Ensure port 4873 is not in use
- Check Verdaccio is running: `curl http://localhost:4873`
- Verify npm registry is set: `npm config get registry`

## Next Steps

After successful local testing:
1. Commit all changes
2. Create git tag: `git tag v0.1.0`
3. Push tag: `git push origin v0.1.0`
4. Publish to npm: `npm publish --access public`
5. Verify on npmjs.com: https://www.npmjs.com/package/@sharia-capital/standard

See [PUBLISHING.md](./PUBLISHING.md) for the complete publishing workflow.
