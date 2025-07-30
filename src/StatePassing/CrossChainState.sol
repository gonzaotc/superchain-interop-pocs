//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IL2ToL2CrossDomainMessenger} from "@optimism/contracts-bedrock/interfaces/L2/IL2ToL2CrossDomainMessenger.sol";
import {Predeploys} from "@optimism/contracts-bedrock/src/libraries/Predeploys.sol";

library StateLib {
    function _sloadUint256(bytes32 slot) internal view returns (uint256 state) {
        assembly {
            state := sload(slot)
        }
    }

    function _sstoreUint256(bytes32 slot, uint256 state) internal {
        assembly {
            sstore(slot, state)
        }
    }
}

contract CrossChainInteraction {
    error OnlyCrossDomainMessenger();

    modifier onlyCrossDomainMessenger() {
        require(msg.sender == Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER, "Only Cross Domain Messenger");
        _;
    }

    IL2ToL2CrossDomainMessenger public immutable messenger =
        IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER);
}

contract SelfCrossChainInteraction is CrossChainInteraction {
    error OnlySelf();
    error OnlyCrosschainSelf();

    modifier onlySelf() {
        require(msg.sender == address(this), "Only Self");
        _;
    }

    modifier onlyCrosschainSelf() {
        address sender = messenger.crossDomainMessageSender();
        require(sender == address(this), "Only Crosschain Self");
        _;
    }
}

contract CrossChainState is SelfCrossChainInteraction {
    using StateLib for *;

    function store(bytes32 slot, uint256 state) external onlyCrosschainSelf {
        StateLib._sstoreUint256(slot, state);
    }

    function load(bytes32 slot) public view onlyCrosschainSelf returns (uint256 state) {
        state = StateLib._sloadUint256(slot);
    }

    // chain a copies the state from chain b into itself
    function copyCrossChainStateOrigin(uint256 chainId, bytes32 slot) public {
        bytes memory message = abi.encodeCall(CrossChainState.copyCrossChainStateDestination, (slot));
        messenger.sendMessage(chainId, address(this), message);
    }

    // receives a request to copy the state from a particular slot and write it back on the caller chain
    function copyCrossChainStateDestination(bytes32 slot) external onlyCrosschainSelf {
        uint256 chainId = messenger.crossDomainMessageSource();
        bytes memory message = abi.encodeCall(CrossChainState.store, (slot, load(slot)));
        messenger.sendMessage(chainId, address(this), message);
    }
}

contract MockCrossChainState is CrossChainState {
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

    function _copyCrossChainState(uint256 chainId, bytes32 slot) internal {
        copyCrossChainStateOrigin(chainId, slot);
    }

    function copACrossChainState_A(uint256 chainId) external {
        _copyCrossChainState(chainId, getASlot());
    }
}
