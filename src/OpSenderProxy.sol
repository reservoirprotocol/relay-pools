// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IHyperlaneMailbox} from "./interfaces/IHyperlaneMailbox.sol";
import {IOpCrossDomainMessenger} from "./interfaces/IOpCrossDomainMessenger.sol";

contract OpSenderProxy {
    // Constants

    address public immutable OP_CROSS_DOMAIN_MESSENGER;
    uint32 public immutable RECEIVER_CHAIN_ID;
    address public immutable HYPERLANE_MAILBOX;

    // Public fields

    uint256 public nextId;

    // Constructor

    constructor(
        address _opCrossDomainMessenger,
        uint32 _receiverChainId,
        address _hyperlaneMailbox
    ) {
        OP_CROSS_DOMAIN_MESSENGER = _opCrossDomainMessenger;
        RECEIVER_CHAIN_ID = _receiverChainId;
        HYPERLANE_MAILBOX = _hyperlaneMailbox;
    }

    // Public methods

    /**
     * @notice Withdraw funds to the base chain
     *
     * @param to Recipient address to receive the funds on the base chain
     * @param opReceiverProxy The corresponding Relay pool on the base chain
     *
     * @return id The withdrawwal id
     */
    function withdraw(
        address to,
        address opReceiverProxy
    ) external payable returns (uint256 id) {
        // Associate the withdrawal to a unique id
        uint256 id = nextId++;

        // Get the Hyperlane fee for a cross-chain message
        uint256 hyperlaneFee = IHyperlaneMailbox(HYPERLANE_MAILBOX)
            .quoteDispatch(
                RECEIVER_CHAIN_ID,
                bytes32(uint256(uint160(opReceiverProxy))),
                // Mock the data to be passed, given that we don't know the amount yet
                abi.encode(id, to, 0)
            );

        // Get the amount left to bridge (initial amount without the Hyperlane fee)
        uint256 amountLeftToBridge = msg.value - hyperlaneFee;

        // Endoce the data to be passed to the receiver chain
        bytes memory data = abi.encode(id, to, amountLeftToBridge);

        // Trigger a Hyperlane cross-chain message to the `opReceiverProxy` contract
        IHyperlaneMailbox(HYPERLANE_MAILBOX).dispatch{value: hyperlaneFee}(
            RECEIVER_CHAIN_ID,
            bytes32(uint256(uint160(opReceiverProxy))),
            data
        );

        // Trigger a canonical withdrawal to the `opReceiverProxy` contract
        IOpCrossDomainMessenger(OP_CROSS_DOMAIN_MESSENGER).sendMessage{
            value: amountLeftToBridge
        }(
            opReceiverProxy,
            data,
            // TODO: Is 200k enough for all base chains?
            200000
        );

        return id;
    }
}
