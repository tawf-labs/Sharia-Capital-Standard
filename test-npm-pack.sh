#!/bin/bash
set -e

echo "🔨 Building contracts..."
forge build

echo ""
echo "📦 Creating npm package tarball..."
npm pack

echo ""
echo "📊 Package contents:"
tar -tzf sharia-capital-standard-*.tgz | head -20
echo "..."
echo ""

echo "📏 Package size:"
ls -lh sharia-capital-standard-*.tgz

echo ""
echo "✅ npm pack test complete!"
echo ""
echo "To test installation:"
echo "  mkdir test-install && cd test-install"
echo "  npm init -y"
echo "  npm install ../sharia-capital-standard-*.tgz"
