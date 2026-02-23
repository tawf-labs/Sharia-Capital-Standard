#!/bin/bash
set -e

echo "🧪 Sharia Capital Standard - Complete Package Test"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Build
echo -e "${BLUE}Step 1: Building contracts...${NC}"
forge build
echo -e "${GREEN}✅ Build complete${NC}"
echo ""

# Step 2: Create package
echo -e "${BLUE}Step 2: Creating npm package...${NC}"
npm pack
PACKAGE_FILE=$(ls sharia-capital-standard-*.tgz)
echo -e "${GREEN}✅ Package created: $PACKAGE_FILE${NC}"
echo ""

# Step 3: Check contents
echo -e "${BLUE}Step 3: Package contents (first 30 files):${NC}"
tar -tzf $PACKAGE_FILE | head -30
echo "..."
echo ""

# Step 4: Check size
echo -e "${BLUE}Step 4: Package size:${NC}"
ls -lh $PACKAGE_FILE
SIZE=$(ls -lh $PACKAGE_FILE | awk '{print $5}')
echo -e "${GREEN}✅ Package size: $SIZE${NC}"
echo ""

# Step 5: Verify key files
echo -e "${BLUE}Step 5: Verifying key files exist...${NC}"
tar -tzf $PACKAGE_FILE | grep -q "package/evm/src/SCS1/MudarabahPool.sol" && echo "✅ SCS1 contracts included"
tar -tzf $PACKAGE_FILE | grep -q "package/evm/src/SCS2/MusharakahPool.sol" && echo "✅ SCS2 contracts included"
tar -tzf $PACKAGE_FILE | grep -q "package/evm/src/SCS3/VaultEngine.sol" && echo "✅ SCS3 contracts included"
tar -tzf $PACKAGE_FILE | grep -q "package/evm/src/SCS4/SCSEnforcement.sol" && echo "✅ SCS4 contracts included"
tar -tzf $PACKAGE_FILE | grep -q "package/evm/src/SCS5/AAOIFIGovernance.sol" && echo "✅ SCS5 contracts included"
tar -tzf $PACKAGE_FILE | grep -q "package/evm/out/" && echo "✅ ABIs included"
tar -tzf $PACKAGE_FILE | grep -q "package/README.md" && echo "✅ README included"
tar -tzf $PACKAGE_FILE | grep -q "package/LICENSE" && echo "✅ LICENSE included"
echo ""

# Step 6: Verify exclusions
echo -e "${BLUE}Step 6: Verifying test files excluded...${NC}"
if tar -tzf $PACKAGE_FILE | grep -q "package/evm/test/"; then
    echo "❌ WARNING: Test files found in package!"
else
    echo "✅ Test files excluded"
fi

if tar -tzf $PACKAGE_FILE | grep -q "package/docs/"; then
    echo "❌ WARNING: Docs directory found in package!"
else
    echo "✅ Docs directory excluded"
fi
echo ""

# Summary
echo "=================================================="
echo -e "${GREEN}✅ Package test complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Test installation: mkdir test && cd test && npm init -y && npm install ../$PACKAGE_FILE"
echo "  2. Test with Verdaccio: ./test-verdaccio.sh (in separate terminal)"
echo "  3. See TESTING-NPM.md for detailed testing guide"
echo ""
