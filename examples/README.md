# Example Integration Projects

This directory contains example projects demonstrating how to integrate Sharia Capital Standard in different environments.

## Foundry Example

See `foundry-example/` for a complete Foundry project using SCS via `forge install`.

## Hardhat Example

See `hardhat-example/` for a complete Hardhat project using SCS via npm.

## Testing the Examples

### Test Foundry Integration
```bash
cd examples/foundry-example
forge install
forge build
forge test
```

### Test Hardhat Integration
```bash
cd examples/hardhat-example
npm install
npx hardhat compile
npx hardhat test
```
