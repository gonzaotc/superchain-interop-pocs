//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IL2ToL2CrossDomainMessenger} from "@eth-optimism/contracts-bedrock/src/L2/IL2ToL2CrossDomainMessenger.sol";
import {Predeploys} from "@eth-optimism/contracts-bedrock/src/libraries/Predeploys.sol";

library StateLib {
    function _sload(bytes32 slot) internal view returns (bytes memory state) {
        assembly {
            state := sload(slot)
        }
    }

    function _sstore(bytes32 slot, bytes memory state) internal {
        assembly {
            sstore(slot, state)
        }
    }
}

contract CrossChainInteraction {
    error OnlyCrossDomainMessenger();

    modifier onlyCrossDomainMessenger() {
        require(msg.sender == Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER, OnlyCrossDomainMessenger());
        _;
    }

    IL2ToL2CrossDomainMessenger public immutable messenger =
        IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER);
}

contract SelfCrossChainInteraction is CrossChainInteraction {
    error OnlySelf();
    error OnlyCrosschainSelf();

    modifier onlySelf() {
        require(msg.sender == address(this), OnlySelf());
        _;
    }

    modifier onlyCrosschainSelf() {
        address sender = messenger.crossDomainMessageSender();
        require(sender == address(this), OnlyCrosschainSelf());
        _;
    }
}

contract CrossChainReader is SelfCrossChainInteraction {
    using StateLib for *;

    function getCrossChainStateOrigin(uint256 chainId, bytes32 slot)
        public
    {
        bytes memory message = abi.encodeCall(CrossChainReadable.getCrossChainStateDestination, (slot));
        messenger.sendMessage(chainId, address(this), message);
    }

    function getCrossChainStateCallback(bytes32 slotTo, bytes memory state) external onlyCrosschainSelf {
        StateLib._sstore(slotTo, state);
    }
}

contract CrossChainReadable is SelfCrossChainInteraction {
    using StateLib for *;

    function getCrossChainStateDestination(bytes32 slot) public onlyCrosschainSelf {
        uint256 chainId = messenger.crossDomainMessageSource();

        bytes memory state = StateLib._sload(slot);

        bytes memory message = abi.encodeCall(CrossChainReader.getCrossChainStateCallback, (slot, state));
        messenger.sendMessage(chainId, address(this), message);
    }
}

contract CrossChainState is CrossChainReader, CrossChainReadable {}


contract A is CrossChainState {
    uint256 public a;

    function setA(uint256 _a) public {
        a = _a;
    }

    function getA() public view returns (uint256) {
        return a;
    }

    function getASlot() public pure returns (bytes32 slot) {
        assembly {
            slot := a.slot
        }
    }

    function setACrossChainStateFrom(uint256 chainId) public {
        getCrossChainStateOrigin(chainId, getASlot());
    }
}
