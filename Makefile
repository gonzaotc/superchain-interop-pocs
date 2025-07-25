# Main Makefile - Entrypoint for cross-chain greeter demo

# Environment variables for local development
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
USER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
URL_CHAIN_A=http://127.0.0.1:9545
URL_CHAIN_B=http://127.0.0.1:9546
INTEROP_BRIDGE=0x4200000000000000000000000000000000000028

# Include specialized makefiles
include message-passing.mk
include crosschain-state.mk

# Main targets
help:
	@echo "Cross-Chain Greeter Demo"
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "Message Passing:"
	@echo "  make deploy           - Deploy both contracts"
	@echo "  make test-greeter     - Test basic greeting on Chain B"
	@echo "  make test-cross-chain - Test cross-chain message passing"
	@echo ""
	@echo "Cross-Chain State:"
	@echo "  make -f crosschain-state.mk deploy    - Deploy A contracts"
	@echo "  make -f crosschain-state.mk demo      - Run state copy demo"
	@echo "  make -f crosschain-state.mk get-a-chain-a"
	@echo "  make -f crosschain-state.mk get-a-chain-b"
	@echo ""
	@echo "Utils:"
	@echo "  make clean           - Clean deployment artifacts"

clean:
	rm -f .env
	rm -rf broadcast/
	rm -rf cache/
	rm -rf out/

.PHONY: help clean 