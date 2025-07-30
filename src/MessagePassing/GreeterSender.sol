//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IL2ToL2CrossDomainMessenger} from "@optimism/contracts-bedrock/interfaces/L2/IL2ToL2CrossDomainMessenger.sol";
import {Predeploys} from "@optimism/contracts-bedrock/src/libraries/Predeploys.sol";

import {Greeter} from "src/MessagePassing/Greeter.sol";

contract GreetingSender {
    IL2ToL2CrossDomainMessenger public immutable messenger =
        IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER);

    address immutable greeterAddress;
    uint256 immutable greeterChainId;

    // State to cache the last known greeting
    string public lastKnownGreeting;

    event CallbackReceived(string updatedGreeting);
    event GreetingFetched(string currentGreeting);

    constructor(address _greeterAddress, uint256 _greeterChainId) {
        greeterAddress = _greeterAddress;
        greeterChainId = _greeterChainId;
    }

    modifier onlyCrossDomainMessenger() {
        require(msg.sender == Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER, "Only cross-domain messenger can call");
        _;
    }

    function setGreeting(string calldata greeting) public {
        bytes memory message = abi.encodeCall(Greeter.setGreeting, (greeting));
        messenger.sendMessage(greeterChainId, greeterAddress, message);
    }

    // Call the Greeter.setGreetingWithCallback and make it call back afterwards.
    function setGreetingWithCallback(string calldata greeting) public {
        // encode the callback data that Greeter should use to call back to this contract
        bytes memory callbackData = abi.encodeCall(this.setGreetingCallback, (greeting));

        // encode the call to Greeter
        bytes memory message = abi.encodeCall(Greeter.setGreetingWithCallback, (greeting, callbackData));

        messenger.sendMessage(greeterChainId, greeterAddress, message);
    }

    // This function will be called by Chain B via cross-domain message
    function setGreetingCallback(string calldata updatedGreeting) external onlyCrossDomainMessenger {
        emit CallbackReceived(updatedGreeting);
    }

    /// @dev Fetch the current greeting value from the other chain
    /// @dev This demonstrates async state reading via callback
    function fetchCurrentGreeting() public {
        // Request the current greeting by asking Greeter to call us back with it
        bytes memory callbackData = abi.encodeCall(this.onGreetingFetched, (""));

        // We use a special "fetch" function on Greeter
        bytes memory message = abi.encodeCall(Greeter.fetchGreetingWithCallback, (callbackData));

        messenger.sendMessage(greeterChainId, greeterAddress, message);
    }

    /// @dev Callback handler for greeting fetch requests
    /// @param fetchedGreeting The current greeting value from the other chain
    function onGreetingFetched(string calldata fetchedGreeting) external onlyCrossDomainMessenger {
        lastKnownGreeting = fetchedGreeting;
        emit GreetingFetched(fetchedGreeting);
    }

    /// @dev Get the last known greeting (cached from previous fetch)
    /// @return The last fetched greeting and when it was updated
    function getLastKnownGreeting() external view returns (string memory) {
        return (lastKnownGreeting);
    }
}
