//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// External
import {IL2ToL2CrossDomainMessenger} from "@optimism/contracts-bedrock/interfaces/L2/IL2ToL2CrossDomainMessenger.sol";
import {Predeploys} from "@optimism/contracts-bedrock/src/libraries/Predeploys.sol";
import {SuperchainTokenBridge} from "@optimism/contracts-bedrock/src/L2/SuperchainTokenBridge.sol";
import {ISuperchainTokenBridge} from "@optimism/contracts-bedrock/interfaces/L2/ISuperchainTokenBridge.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Internal
import {MySuperchainERC20} from "src/Swapping/MySuperchainERC20.sol";

contract Swapper {
    IL2ToL2CrossDomainMessenger public immutable messenger =
        IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER);

    modifier onlyCrossDomainMessenger() {
        require(msg.sender == Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER, "Only cross-domain messenger can call");
        _;
    }

    modifier onlyCrosschainSelf() {
        address sender = messenger.crossDomainMessageSender();
        require(sender == address(this), "Only crosschain self can call");
        _;
    }

    // Bridge tokens from this contract to the destination chain
    function bridge(address token, address to, uint256 amount, uint256 chainId) public {
        ISuperchainTokenBridge(Predeploys.SUPERCHAIN_TOKEN_BRIDGE).sendERC20(token, to, amount, chainId);
    }

    // Take tokens from the user and bridge them to the destination chain
    function takeAndBridge(address token, address to, uint256 amount, uint256 chainId) public {
        // User must approve Swapper to spend their tokens first
        require(IERC20(token).allowance(to, address(this)) >= amount, "Insufficient allowance");

        // Transfer tokens from user to this contract
        IERC20(token).transferFrom(to, address(this), amount);

        // Bridge
        bridge(token, to, amount, chainId);
    }

    // Take tokens from the user only if required and bridge them to the destination chain.
    function conditionalTakeAndBridge(address token, address to, uint256 amount, uint256 chainId) public {
        if (IERC20(token).balanceOf(address(this)) >= amount) {
            bridge(token, to, amount, chainId);
        } else {
            takeAndBridge(token, to, amount, chainId);
        }
    }

    // chain A calls chain B to ask it to bridge to it!
    function bridgeBack(address token, address to, uint256 amount, uint256 chainIdOrigin, uint256 chainIdDestination)
        public
    {
        bytes memory message = abi.encodeCall(this.takeAndBridge, (token, to, amount, chainIdOrigin));
        messenger.sendMessage(chainIdDestination, address(this), message);
    }

    // Bridge and come back!
    function doubleBridge(address token, address to, uint256 amount, uint256 chainIdOrigin, uint256 chainIdDestination)
        public
    {
        // bridge (a burns and emits a cross chain message for the chain b to mint the tokens)
        takeAndBridge(token, to, amount, chainIdDestination);

        // bridge back (a emits a cross chain message for chain b to bridge back to a)
        // -> then, chain b will burn and emit a cross chain message for the chain a to mint the tokens
        bridgeBack(token, to, amount, chainIdOrigin, chainIdDestination);
    }
}
