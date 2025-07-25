# CrossChainState Makefile - Basic cross-chain state functionality

# Environment variables (duplicate from main Makefile for standalone usage)
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
USER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
URL_CHAIN_A=http://127.0.0.1:9545
URL_CHAIN_B=http://127.0.0.1:9546
INTEROP_BRIDGE=0x4200000000000000000000000000000000000028

# Deploy A contract on both chains
deploy-crosschain-state:
	@echo "Deploying A contracts..."
	# Deploy A contract to Chain B
	$(eval A_B_ADDRESS := $(shell forge create --rpc-url $(URL_CHAIN_B) --private-key $(PRIVATE_KEY) A --broadcast | awk '/Deployed to:/ {print $$3}'))
	@echo "A deployed to Chain B at: $(A_B_ADDRESS)"
	@echo "A_B_ADDRESS=$(A_B_ADDRESS)" > .env
	@if [ -z "$(A_B_ADDRESS)" ]; then echo "ERROR: Failed to deploy to Chain B"; exit 1; fi
	
	# Deploy A contract to Chain A
	$(eval A_A_ADDRESS := $(shell forge create --rpc-url $(URL_CHAIN_A) --private-key $(PRIVATE_KEY) A --broadcast | awk '/Deployed to:/ {print $$3}'))
	@echo "A deployed to Chain A at: $(A_A_ADDRESS)"
	@echo "A_A_ADDRESS=$(A_A_ADDRESS)" >> .env
	@if [ -z "$(A_A_ADDRESS)" ]; then echo "ERROR: Failed to deploy to Chain A"; exit 1; fi
	
	# Store chain IDs for later use
	$(eval CHAIN_ID_A := $(shell cast chain-id --rpc-url $(URL_CHAIN_A)))
	$(eval CHAIN_ID_B := $(shell cast chain-id --rpc-url $(URL_CHAIN_B)))
	@echo "CHAIN_ID_A=$(CHAIN_ID_A)" >> .env
	@echo "CHAIN_ID_B=$(CHAIN_ID_B)" >> .env
	@echo "Deployment complete! Run 'cat .env' to see addresses."

set-chain-a:
	@echo "Setting a=100 on Chain A..."
	@. ./.env && cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_A) $$A_A_ADDRESS "setA(uint256)" 100

set-chain-b:
	@echo "Setting a=42 on Chain B..."
	@. ./.env && cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_B) $$A_B_ADDRESS "setA(uint256)" 42

get-chain-a:
	@echo -n "a on Chain A: "
	@. ./.env && cast call --rpc-url $(URL_CHAIN_A) $$A_A_ADDRESS "getA()"

get-chain-b:
	@echo -n "a on Chain B: "
	@. ./.env && cast call --rpc-url $(URL_CHAIN_B) $$A_B_ADDRESS "getA()"

copy-from-chain-b-to-chain-a:
	@echo "Copying state from Chain B to Chain A..."
	@. ./.env && cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_B) $$A_B_ADDRESS "setACrossChainStateFrom(uint256)" $$CHAIN_ID_A
	@echo "Waiting for cross-chain message..."
	@sleep 4

