#!/bin/bash
set -e

echo "🚀 Setting up Verdaccio local npm registry..."
echo ""

# Check if Verdaccio is installed
if ! command -v verdaccio &> /dev/null; then
    echo "📥 Installing Verdaccio..."
    npm install -g verdaccio
fi

echo "🔧 Starting Verdaccio on http://localhost:4873"
echo "   (Press Ctrl+C to stop)"
echo ""
echo "In another terminal, run:"
echo "  1. npm adduser --registry http://localhost:4873"
echo "  2. npm publish --registry http://localhost:4873"
echo "  3. mkdir test-verdaccio && cd test-verdaccio"
echo "  4. npm install @tawf-labs/sharia-capital-standard --registry http://localhost:4873"
echo ""

verdaccio
