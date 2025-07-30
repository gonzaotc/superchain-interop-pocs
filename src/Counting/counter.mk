# Counter Makefile - Basic cross-chain messaging functionality

COUNTER_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3

# Deploy Counter contracts
deploy-counter:
	# Deploy Counter to Chain A
	$(eval CHAIN_ID_B := $(shell cast chain-id --rpc-url $(URL_CHAIN_B)))
	$(eval COUNTER_ADDRESS := $(shell forge create --rpc-url $(URL_CHAIN_A) --private-key $(PRIVATE_KEY) --broadcast Counter | awk '/Deployed to:/ {print $$3}'))
	@echo "Counter deployed to Chain A at: $(COUNTER_ADDRESS)"

	# Deploy Counter contract to Chain B
	$(eval COUNTER_ADDRESS := $(shell forge create --rpc-url $(URL_CHAIN_B) --private-key $(PRIVATE_KEY) Counter --broadcast | awk '/Deployed to:/ {print $$3}'))
	@echo "Counter deployed to Chain B at: $(COUNTER_ADDRESS)"

counter-a:
	@echo "counter on Chain A:"
	cast call --rpc-url $(URL_CHAIN_A) $(COUNTER_ADDRESS) "counter()"

counter-b:
	@echo "counter on Chain B:"
	cast call --rpc-url $(URL_CHAIN_B) $(COUNTER_ADDRESS) "counter()"

counters:
	make counter-a
	@echo ""
	make counter-b

crosschain-count-a-to-b-to-a:
	@echo "crosschainCountAndCallbackCount() on Chain A:"
	cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_A) $(COUNTER_ADDRESS) "crosschainCountAndCallbackCount(uint256,uint256)" $(CHAIN_ID_A) $(CHAIN_ID_B)

