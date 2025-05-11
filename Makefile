# BITSI v4-template Makefile
# Address:     0x1942913cE83A919200C518c7cd08f990c686b966
# Private key: 0x85fc0d4c5af249a7c637fb523f92a2b2515a7f2a405566c205dfbd4d67f78001


.PHONY: all build test test-verbosity test-single clean format gas-snapshot anvil deploy deploy-anvil create-pool update-deps help run run-local check-balances wrap-eth

all: build

# Build the project
build:
	forge build

# Run all tests
test:
	forge test

# Run tests with verbose output
test-verbosity:
	forge test -vvv

# Run a single test file
# Usage: make test-single TEST=<test-file-path>
test-single:
	forge test --match-path $(TEST)

# Clean build artifacts
clean:
	forge clean

# Format code
format:
	forge fmt

# Generate gas snapshots
gas-snapshot:
	forge snapshot

# Run local Anvil node
anvil:
	anvil --code-size-limit 40000

# Deploy script for general deployment
# Usage: make deploy SCRIPT=<script-path> RPC_URL=<rpc-url> PRIVATE_KEY=<private-key>
deploy:
	forge script $(SCRIPT) --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast -vvv

# Deploy on local Anvil chain
deploy-anvil:
	forge script script/Anvil.s.sol \
	--rpc-url http://localhost:8545 \
	--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
	--broadcast

# Create pool and mint liquidity
# Usage: make create-pool [CHAIN_ID=<chain-id>]
create-pool:
	./run_create_pool.sh $(CHAIN_ID)

# Update dependencies
update-deps:
	forge update

# Run deployment on Sepolia testnet
run:
	PRIVATE_KEY=0x85fc0d4c5af249a7c637fb523f92a2b2515a7f2a405566c205dfbd4d67f78001 ./run_create_pool.sh

# Run deployment on local Anvil instance
run-local:
	./run_create_pool.sh 31337

# Check token balances
check-balances:
	PRIVATE_KEY=0x85fc0d4c5af249a7c637fb523f92a2b2515a7f2a405566c205dfbd4d67f78001 forge script script/CheckTokenBalances.s.sol --rpc-url https://ethereum-sepolia.rpc.subquery.network/public -vvv

# Wrap ETH to WETH
wrap-eth:
	PRIVATE_KEY=0x85fc0d4c5af249a7c637fb523f92a2b2515a7f2a405566c205dfbd4d67f78001 forge script script/WrapETH.s.sol --rpc-url https://ethereum-sepolia.rpc.subquery.network/public --broadcast -vvv

# Show help
help:
	@echo "Available targets:"
	@echo "  all             - Build the project"
	@echo "  build           - Build the project"
	@echo "  test            - Run all tests"
	@echo "  test-verbosity  - Run tests with verbose output"
	@echo "  test-single     - Run a single test file (TEST=<test-file-path>)"
	@echo "  clean           - Clean build artifacts"
	@echo "  format          - Format code"
	@echo "  gas-snapshot    - Generate gas snapshots"
	@echo "  anvil           - Run local Anvil node"
	@echo "  deploy          - Deploy script (SCRIPT=<script-path> RPC_URL=<rpc-url> PRIVATE_KEY=<private-key>)"
	@echo "  deploy-anvil    - Deploy on local Anvil chain"
	@echo "  create-pool     - Create pool and mint liquidity [CHAIN_ID=<chain-id>]"
	@echo "  run             - Run deployment on Sepolia testnet (chain ID 11155111)"
	@echo "  run-local       - Run deployment on local Anvil instance"
	@echo "  check-balances  - Check token balances for the account on Sepolia"
	@echo "  update-deps     - Update dependencies"
	@echo "  help            - Show this help message"
