# Main Makefile - Entrypoint for cross-chain greeter demo

# Environment variables for local development
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
USER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
URL_CHAIN_A=http://127.0.0.1:9545
URL_CHAIN_B=http://127.0.0.1:9546
CHAIN_ID_A=901
CHAIN_ID_B=902
INTEROP_BRIDGE=0x4200000000000000000000000000000000000028

# Include specialized makefiles
include src/MessagePassing/message-passing.mk
include src/StatePassing/crosschain-state.mk
include src/Swapping/swapping.mk
include src/Counting/counter.mk

clean:
	rm -f .env
	rm -rf broadcast/
	rm -rf cache/
	rm -rf out/

.PHONY: clean