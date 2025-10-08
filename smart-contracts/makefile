# Load environment variables from .env file
include .env
export
# Deploy to testnet (e.g., Sepolia)
deploy-testnet:
	@echo "Deploying to testnet..."
	forge script script/Deploy.s.sol:Deploy --rpc-url $(TESTNET_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)
	@echo "Testnet deployment complete!"