//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IL2ToL2CrossDomainMessenger} from "@optimism/contracts-bedrock/interfaces/L2/IL2ToL2CrossDomainMessenger.sol";
import {Predeploys} from "@optimism/contracts-bedrock/src/libraries/Predeploys.sol";

contract Greeter {
    IL2ToL2CrossDomainMessenger public immutable messenger =
        IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER);

    string greeting;

    event SetGreeting(address indexed sender, string greeting);

    // sender: Sender on the other side
    // chainId: ChainID of the other side
    // greeting: Greeting set on the other side
    event CrossDomainSetGreeting(address indexed sender, uint256 indexed chainId, string greeting);

    // Event for callback operations
    event CallbackSent(address indexed target, uint256 indexed targetChainId, bytes callbackData);

    modifier onlyCrossDomainMessenger() {
        require(msg.sender == Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER, "Only cross-domain messenger can call");
        _;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreetingSelf(string memory _greeting) public {
        greeting = _greeting;
        emit SetGreeting(msg.sender, _greeting);
    }

    function setGreeting(string memory _greeting) public onlyCrossDomainMessenger {
        greeting = _greeting;
        emit SetGreeting(msg.sender, _greeting);

        if (msg.sender == Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER) {
            (address sender, uint256 chainId) = messenger.crossDomainMessageContext();
            emit CrossDomainSetGreeting(sender, chainId, _greeting);
        }
    }

    /// @dev Sets greeting and executes a callback to the original sender
    /// @param _greeting The greeting message to set
    /// @param _callbackData The exact calldata to send back to the sender
    function setGreetingWithCallback(string memory _greeting, bytes calldata _callbackData)
        public
        onlyCrossDomainMessenger
    {
        greeting = _greeting;
        emit SetGreeting(msg.sender, _greeting);

        (address sender, uint256 chainId) = messenger.crossDomainMessageContext();
        emit CrossDomainSetGreeting(sender, chainId, _greeting);

        // Send the provided callback data to the original sender
        messenger.sendMessage(chainId, sender, _callbackData);
        emit CallbackSent(sender, chainId, _callbackData);
    }

    /// @dev Fetches the current greeting and sends it back via callback
    /// @param _callbackData The callback data to execute, but with greeting inserted
    /// @dev NOTE: The callback function should expect the greeting as its first parameter
    function fetchGreetingWithCallback(bytes calldata _callbackData) public onlyCrossDomainMessenger {
        (address sender, uint256 chainId) = messenger.crossDomainMessageContext();

        // Extract the function selector from callbackData
        bytes4 selector = bytes4(_callbackData[:4]);

        // Reconstruct the callback with the current greeting as first parameter
        bytes memory callbackWithGreeting = abi.encodePacked(selector, abi.encode(greeting));

        messenger.sendMessage(chainId, sender, callbackWithGreeting);
        emit CallbackSent(sender, chainId, callbackWithGreeting);
    }
}
