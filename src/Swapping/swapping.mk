# Swapping Makefile - Basic cross-chain messaging functionality

SWAPPER_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
SUPERCHAIN_ERC20_ADDRESS=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

# Deploy Swapper and SuperchainERC20 contracts
deploy-swapping:
	# Deploy Swapper to Chain A
	$(eval CHAIN_ID_B := $(shell cast chain-id --rpc-url $(URL_CHAIN_B)))
	$(eval SWAPPER_ADDRESS := $(shell forge create --rpc-url $(URL_CHAIN_A) --private-key $(PRIVATE_KEY) --broadcast Swapper | awk '/Deployed to:/ {print $$3}'))
	@echo "Swapper deployed to Chain A at: $(SWAPPER_ADDRESS)"

	# Deploy Swapper contract to Chain B
	$(eval SWAPPER_ADDRESS := $(shell forge create --rpc-url $(URL_CHAIN_B) --private-key $(PRIVATE_KEY) Swapper --broadcast | awk '/Deployed to:/ {print $$3}'))
	@echo "Swapper deployed to Chain B at: $(SWAPPER_ADDRESS)"

	# Deploy SuperchainERC20 contract to Chain A
	$(eval SUPERCHAIN_ERC20_ADDRESS := $(shell forge create --rpc-url $(URL_CHAIN_A) --private-key $(PRIVATE_KEY) MySuperchainERC20 --broadcast | awk '/Deployed to:/ {print $$3}'))
	@echo "SuperchainERC20 deployed to Chain A at: $(SUPERCHAIN_ERC20_ADDRESS)"

	# Deploy SuperchainERC20 contract to Chain B
	$(eval SUPERCHAIN_ERC20_ADDRESS := $(shell forge create --rpc-url $(URL_CHAIN_B) --private-key $(PRIVATE_KEY) MySuperchainERC20 --broadcast | awk '/Deployed to:/ {print $$3}'))
	@echo "SuperchainERC20 deployed to Chain B at: $(SUPERCHAIN_ERC20_ADDRESS)"

mint-token-a:
	@echo "mintToken() on Chain A:"
	cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_A) $(SUPERCHAIN_ERC20_ADDRESS) "mintToken(address,uint256)" $(USER_ADDRESS) 1000000000000000000

mint-token-b:
	@echo "mintToken() on Chain B:"
	cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_B) $(SUPERCHAIN_ERC20_ADDRESS) "mintToken(address,uint256)" $(USER_ADDRESS) 1000000000000000000

approve-swapper-a:
	@echo "approve() on Chain A:"
	cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_A) $(SUPERCHAIN_ERC20_ADDRESS) "approve(address,uint256)" $(SWAPPER_ADDRESS) 1000000000000000000

approve-swapper-b:
	@echo "approve() on Chain B:"
	cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_B) $(SUPERCHAIN_ERC20_ADDRESS) "approve(address,uint256)" $(SWAPPER_ADDRESS) 1000000000000000000

allowances:
	make allowance-swapper-a
	@echo ""
	make allowance-swapper-b

allowance-swapper-a:
	@echo "token.allowance(user, swapper) on Chain A:"
	$(eval HEX_ALLOWANCE := $(shell cast call --rpc-url $(URL_CHAIN_A) $(SUPERCHAIN_ERC20_ADDRESS) "allowance(address,address)" $(USER_ADDRESS) $(SWAPPER_ADDRESS)))
	$(eval DEC_ALLOWANCE := $(shell cast to-dec $(HEX_ALLOWANCE)))
	@echo $(DEC_ALLOWANCE)

allowance-swapper-b:
	@echo "token.allowance(user, swapper) on Chain B:"
	$(eval HEX_ALLOWANCE := $(shell cast call --rpc-url $(URL_CHAIN_B) $(SUPERCHAIN_ERC20_ADDRESS) "allowance(address,address)" $(USER_ADDRESS) $(SWAPPER_ADDRESS)))
	$(eval DEC_ALLOWANCE := $(shell cast to-dec $(HEX_ALLOWANCE)))
	@echo $(DEC_ALLOWANCE)

balances:
	make balance-user-a
	@echo ""
	make balance-swapper-a
	@echo ""
	make balance-user-b
	@echo ""
	make balance-swapper-b

balance-user-a:
	@echo "token.balanceOf(user) on Chain A:"
	$(eval HEX_BALANCE := $(shell cast call --rpc-url $(URL_CHAIN_A) $(SUPERCHAIN_ERC20_ADDRESS) "balanceOf(address)" $(USER_ADDRESS)))
	$(eval DEC_BALANCE := $(shell cast to-dec $(HEX_BALANCE)))
	@echo $(DEC_BALANCE)

balance-user-b:
	@echo "token.balanceOf(user) on Chain B:"
	$(eval HEX_BALANCE := $(shell cast call --rpc-url $(URL_CHAIN_B) $(SUPERCHAIN_ERC20_ADDRESS) "balanceOf(address)" $(USER_ADDRESS)))
	$(eval DEC_BALANCE := $(shell cast to-dec $(HEX_BALANCE)))
	@echo $(DEC_BALANCE)

balance-swapper-a:
	@echo "token.balanceOf(swapper) on Chain A:"
	$(eval HEX_BALANCE := $(shell cast call --rpc-url $(URL_CHAIN_A) $(SUPERCHAIN_ERC20_ADDRESS) "balanceOf(address)" $(SWAPPER_ADDRESS)))
	$(eval DEC_BALANCE := $(shell cast to-dec $(HEX_BALANCE)))
	@echo $(DEC_BALANCE)

balance-swapper-b:
	@echo "token.balanceOf(swapper) on Chain B:"
	$(eval HEX_BALANCE := $(shell cast call --rpc-url $(URL_CHAIN_B) $(SUPERCHAIN_ERC20_ADDRESS) "balanceOf(address)" $(SWAPPER_ADDRESS)))
	$(eval DEC_BALANCE := $(shell cast to-dec $(HEX_BALANCE)))
	@echo $(DEC_BALANCE)

setup:
	make deploy-swapping
	make mint-token-a
	make balance-user-a
	make approve-swapper-a
	make allowance-swapper-a
	make approve-swapper-b
	make allowance-swapper-b

bridge-a-to-b:
	@echo "takeAndBridge() on Chain A:"
	cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_A) $(SWAPPER_ADDRESS) "takeAndBridge(address,address,uint256,uint256)" $(SUPERCHAIN_ERC20_ADDRESS) $(USER_ADDRESS) 1000000000000000000 $(CHAIN_ID_B)

bridge-b-to-a:
	@echo "takeAndBridge() on Chain B:"
	cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_B) $(SWAPPER_ADDRESS) "takeAndBridge(address,address,uint256,uint256)" $(SUPERCHAIN_ERC20_ADDRESS) $(USER_ADDRESS) 1000000000000000000 $(CHAIN_ID_A)

bridge-back:
	@echo "bridgeBack() on Chain A:"
	cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_A) $(SWAPPER_ADDRESS) "bridgeBack(address,address,uint256,uint256,uint256)" $(SUPERCHAIN_ERC20_ADDRESS) $(USER_ADDRESS) 1000000000000000000 $(CHAIN_ID_A) $(CHAIN_ID_B)

bridge-a-to-b-to-a:
	@echo "doubleBridge() on Chain A:"
	cast send --private-key $(PRIVATE_KEY) --rpc-url $(URL_CHAIN_A) $(SWAPPER_ADDRESS) "doubleBridge(address,address,uint256,uint256,uint256)" $(SUPERCHAIN_ERC20_ADDRESS) $(USER_ADDRESS) 1000000000000000000 $(CHAIN_ID_A) $(CHAIN_ID_B)

.PHONY: deploy-swapping