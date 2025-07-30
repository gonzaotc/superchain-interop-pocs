//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// External
import {IL2ToL2CrossDomainMessenger} from "@optimism/contracts-bedrock/interfaces/L2/IL2ToL2CrossDomainMessenger.sol";
import {Predeploys} from "@optimism/contracts-bedrock/src/libraries/Predeploys.sol";

contract Counter {
    uint256 public counter;

    IL2ToL2CrossDomainMessenger public immutable messenger =
        IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER);

    modifier onlyCrossDomainMessenger() {
        require(msg.sender == Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER, "Only cross-domain messenger can call");
        _;
    }

    event Called();

    function count() public {
        counter++;
    }

    // call from a to b to execute count()
    function crossChainCount(uint256 chainId) public {
        bytes memory message = abi.encodeCall(this.count, ());
        messenger.sendMessage(chainId, address(this), message);
    }

    // call count in a and then make b call count.
    function countAndCrossChainCount(uint256 chainId) external {
        count();
        crossChainCount(chainId);
    }

    // call from a to b, which makes b to count and then call a count
    function crosschainCountAndCallbackCount(uint256 chainIdOrigin, uint256 chainIdDestination) external {
        // make a call b `countAndCrossChainCount`, where it should call count and then crossChainCount on chainIdOrigin (a)
        bytes memory message = abi.encodeCall(this.countAndCrossChainCount, (chainIdOrigin));
        messenger.sendMessage(chainIdDestination, address(this), message);
    }
}
