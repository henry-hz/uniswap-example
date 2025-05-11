#!/bin/bash

# This script runs the SepoliaCreatePool script using Forge
# Specifically configured for Ethereum Sepolia (chain ID 11155111)
# with position manager address 0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4

# Set chain ID to Ethereum Sepolia (11155111)
CHAIN_ID="11155111"
echo "Using Ethereum Sepolia (Chain ID: $CHAIN_ID)"

# Check if private key is provided
if [ -z "$PRIVATE_KEY" ]; then
  echo "Error: PRIVATE_KEY environment variable required"
  echo "Usage: PRIVATE_KEY=your_private_key ./run_create_pool.sh"
  exit 1
fi
PRIVATE_KEY_ARG="--private-key $PRIVATE_KEY"

# Set RPC URL for Ethereum Sepolia
RPC_URL="https://ethereum-sepolia.rpc.subquery.network/public"
echo "Using RPC URL: $RPC_URL"

# Position Manager Address for Ethereum Sepolia is configured in PositionManagerAddresses.sol
echo "Using Sepolia Position Manager from PositionManagerAddresses.sol"

# Run the Sepolia-specific script
echo "Running SepoliaCreatePool script..."
forge script script/01a_SepoliaCreatePool.s.sol \
  --rpc-url "$RPC_URL" \
  $PRIVATE_KEY_ARG \
  --broadcast \
  -vvv \
  --slow

echo "Script execution completed."