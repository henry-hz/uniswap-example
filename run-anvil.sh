#!/bin/bash

# Create log directory
mkdir -p /home/henry/bitsi/uniswap-example/forge-logs/Deploy.s.sol

# Kill any running anvil processes
echo "Stopping any existing anvil instances..."
pkill -f anvil || true

# Start anvil with a fixed mnemonic for reproducibility
echo "Starting anvil..."
anvil --mnemonic "test test test test test test test test test test test junk" > anvil.log 2>&1 &
ANVIL_PID=$!

# Sleep to make sure anvil has started
echo "Waiting for anvil to start..."
sleep 5

# Deploy the contracts
echo "Deploying contracts..."
DEPLOY_OUTPUT=$(forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvv)
echo "$DEPLOY_OUTPUT"

# Manually extract the addresses from the deployment output
TOKEN_A=$(echo "$DEPLOY_OUTPUT" | grep "Token A deployed at:" | awk '{print $NF}')
TOKEN_B=$(echo "$DEPLOY_OUTPUT" | grep "Token B deployed at:" | awk '{print $NF}')
INTERACTOR=$(echo "$DEPLOY_OUTPUT" | grep "UniswapV4Interactor deployed at:" | awk '{print $NF}')
POOL_MANAGER=$(echo "$DEPLOY_OUTPUT" | grep "PoolManager deployed at:" | awk '{print $NF}')

# Save the addresses to a file for reference
echo "TOKEN_A=$TOKEN_A" > deploy_addresses.env
echo "TOKEN_B=$TOKEN_B" >> deploy_addresses.env
echo "INTERACTOR=$INTERACTOR" >> deploy_addresses.env
echo "POOL_MANAGER=$POOL_MANAGER" >> deploy_addresses.env

echo "Deployed addresses:"
echo "Token A: $TOKEN_A"
echo "Token B: $TOKEN_B"
echo "Interactor: $INTERACTOR"
echo "Pool Manager: $POOL_MANAGER"

# Run the check status script 
echo "Checking status after deployment..."
TOKEN_A=$TOKEN_A TOKEN_B=$TOKEN_B INTERACTOR=$INTERACTOR forge script script/CheckStatus.s.sol --rpc-url http://127.0.0.1:8545 -vvv

# Prompt user if they want to add liquidity
read -p "Would you like to add liquidity to the pool? (y/n) " ADDLIQ

if [ "$ADDLIQ" = "y" ]; then
    echo "Adding liquidity with addresses:"
    echo "Token A: $TOKEN_A"
    echo "Token B: $TOKEN_B"
    echo "Interactor: $INTERACTOR"
    
    # Run the add liquidity script with environment variables
    TOKEN_A=$TOKEN_A TOKEN_B=$TOKEN_B INTERACTOR=$INTERACTOR forge script script/AddLiquidity.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvv
    
    # Check status again after adding liquidity
    echo "Checking status after adding liquidity..."
    TOKEN_A=$TOKEN_A TOKEN_B=$TOKEN_B INTERACTOR=$INTERACTOR forge script script/CheckStatus.s.sol --rpc-url http://127.0.0.1:8545 -vvv
fi

# Ask if the user wants to keep anvil running
read -p "Would you like to keep anvil running? (y/n) " KEEPANVIL

if [ "$KEEPANVIL" != "y" ]; then
    echo "Stopping anvil..."
    kill $ANVIL_PID
    echo "Done."
else
    echo "Anvil is still running with PID $ANVIL_PID"
    echo "Press Ctrl+C to stop it when you're done."
    wait $ANVIL_PID
fi