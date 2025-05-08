#!/bin/bash

# Check if anvil is running
if ! pgrep -x "anvil" > /dev/null; then
    echo "Starting Anvil..."
    anvil --mnemonic "test test test test test test test test test test test junk" > anvil.log 2>&1 &
    sleep 3
fi

# Clean existing builds
echo "Cleaning previous builds..."
forge clean

# Build project
echo "Building project..."
forge build

# Deploy contracts
echo "Deploying contracts..."
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast -vvv

echo "Deployment completed!"