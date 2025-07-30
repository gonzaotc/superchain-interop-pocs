# CrossChainState Makefile - Basic cross-chain state functionality

# Environment variables (duplicate from main Makefile for standalone usage)
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
USER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
URL_CHAIN_A=http://127.0.0.1:9545
URL_CHAIN_B=http://127.0.0.1:9546
INTEROP_BRIDGE=0x4200000000000000000000000000000000000028

A_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3

# Deploy A contract on both chains
deploy-crosschain-state:
	@echo "Deploying A contracts..."
	# Deploy A contract to Chain A
	forge create --rpc-url $(URL_CHAIN_A) --private-key $(PRIVATE_KEY) MockCrossChainState --broadcast
	@echo "A deployed to Chain A at: $(A_ADDRESS)"

	# Deploy A contract to Chain B
	forge create --rpc-url $(URL_CHAIN_B) --private-key $(PRIVATE_KEY) MockCrossChainState --broadcast
	@echo "A deployed to Chain B at: $(A_ADDRESS)"
	
set-chain-a:
	@echo "Setting a=100 on Chain A..."
	@. ./.env && cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_A) $(A_ADDRESS) "setA(uint256)" 100

set-chain-b:
	@echo "Setting a=42 on Chain B..."
	@. ./.env && cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_B) $(A_ADDRESS) "setA(uint256)" 42

get-chain-a:
	@echo -n "a on Chain A: "
	$(eval HEX_VALUE := $(shell cast call --rpc-url $(URL_CHAIN_A) $(A_ADDRESS) "getA()"))
	$(eval DEC_VALUE := $(shell cast to-dec $(HEX_VALUE)))
	@echo $(DEC_VALUE)

get-chain-b:
	@echo -n "a on Chain B: "
	$(eval HEX_VALUE := $(shell cast call --rpc-url $(URL_CHAIN_B) $(A_ADDRESS) "getA()"))
	$(eval DEC_VALUE := $(shell cast to-dec $(HEX_VALUE)))
	@echo $(DEC_VALUE)

copy-from-b-to-a:
	@echo "Copying state from Chain B to Chain A..."
	@. ./.env && cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_A) $(A_ADDRESS) "copACrossChainState_A(uint256)" $(CHAIN_ID_B)
	@echo "Waiting for cross-chain message..."
	@sleep 4

