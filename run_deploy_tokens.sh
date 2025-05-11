#!/bin/bash

# This script deploys test tokens only
# Specifically configured for Ethereum Sepolia (chain ID 11155111)

# Set chain ID to Ethereum Sepolia (11155111)
CHAIN_ID="11155111"
echo "Using Ethereum Sepolia (Chain ID: $CHAIN_ID)"

# Check if private key is provided
if [ -z "$PRIVATE_KEY" ]; then
  echo "Error: PRIVATE_KEY environment variable required"
  echo "Usage: PRIVATE_KEY=your_private_key ./run_deploy_tokens.sh"
  exit 1
fi
PRIVATE_KEY_ARG="--private-key $PRIVATE_KEY"

# Set RPC URL for Ethereum Sepolia
RPC_URL="https://ethereum-sepolia.rpc.subquery.network/public"
echo "Using RPC URL: $RPC_URL"

# Run the script to deploy tokens
echo "Running DeployTestTokens script..."
forge script script/04_DeployTestTokens.s.sol \
  --rpc-url "$RPC_URL" \
  $PRIVATE_KEY_ARG \
  --broadcast \
  -vvv \
  --slow

echo "Script execution completed."