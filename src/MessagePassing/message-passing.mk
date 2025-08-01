# Message Passing Makefile - Basic cross-chain messaging functionality

# Deploy Greeter and GreetingSender contracts
deploy-message-passing:
	# Deploy Greeter contract to Chain B
	$(eval GREETER_B_ADDRESS := $(shell forge create --rpc-url $(URL_CHAIN_B) --private-key $(PRIVATE_KEY) Greeter --broadcast | awk '/Deployed to:/ {print $$3}'))
	@echo "Greeter deployed to Chain B at: $(GREETER_B_ADDRESS)"
	@echo "GREETER_B_ADDRESS=$(GREETER_B_ADDRESS)" > .env
	# Deploy GreetingSender to Chain A
	$(eval CHAIN_ID_B := $(shell cast chain-id --rpc-url $(URL_CHAIN_B)))
	$(eval GREETER_A_ADDRESS := $(shell forge create --rpc-url $(URL_CHAIN_A) --private-key $(PRIVATE_KEY) --broadcast GreetingSender --constructor-args $(GREETER_B_ADDRESS) $(CHAIN_ID_B) | awk '/Deployed to:/ {print $$3}'))
	@echo "GreetingSender deployed to Chain A at: $(GREETER_A_ADDRESS)"
	@echo "GREETER_A_ADDRESS=$(GREETER_A_ADDRESS)" >> .env

# Test basic greeting on Chain B
test-greeter:
	@echo "greet() on Chain B:"
	@. ./.env && cast call --rpc-url $(URL_CHAIN_B) $$GREETER_B_ADDRESS "greet()" | cast --to-ascii
	@echo ""

	@echo "setGreeting(string) on Chain B (direct):"
	@. ./.env && cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_B) $$GREETER_B_ADDRESS "setGreeting(string)" "Hello directly on Chain B"
	@echo ""

	@echo "greet() on Chain B:"
	@. ./.env && cast call --rpc-url $(URL_CHAIN_B) $$GREETER_B_ADDRESS "greet()" | cast --to-ascii
	@echo ""

# Test cross-chain messaging
test-cross-chain:
	@echo "greet() on Chain B (before):"
	@. ./.env && cast call --rpc-url $(URL_CHAIN_B) $$GREETER_B_ADDRESS "greet()" | cast --to-ascii
	@echo ""

	@echo "setGreeting(string) via Chain A → Chain B:"
	@. ./.env && cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_A) $$GREETER_A_ADDRESS "setGreeting(string)" "Hello from chain A"
	@sleep 4 # Wait for cross-chain message
	@echo ""

	@echo "greet() on Chain B (after cross-chain):"
	@. ./.env && cast call --rpc-url $(URL_CHAIN_B) $$GREETER_B_ADDRESS "greet()" | cast --to-ascii
	@echo ""

.PHONY: deploy test-greeter test-cross-chain 