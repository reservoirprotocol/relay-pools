pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {OpReceiverProxy} from "../src/OpReceiverProxy.sol";
import {OpSenderProxy} from "../src/OpSenderProxy.sol";

contract DeployOpReceiverProxy is Script {
    address constant ARACHNID_CREATE2_FACTORY =
        0x4e59b44847b379578588920cA78FbF26c0B4956C;

    function run() public {
        vm.startBroadcast();

        // Load constructor parameters for `OpSenderProxy`
        address senderProxy_opCrossDomainMessenger = vm.envAddress(
            "SENDER_PROXY_OP_CROSS_DOMAIN_MESSENGER"
        );
        uint32 senderProxy_receiverChainId = uint32(
            vm.envUint("SENDER_PROXY_RECEIVER_CHAIN_ID")
        );
        address senderProxy_hyperlaneMailbox = vm.envAddress(
            "SENDER_PROXY_HYPERLANE_MAILBOX"
        );

        // Determine the address `OpSenderProxy` will get deployed at
        address predictedSenderProxyAddress = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            ARACHNID_CREATE2_FACTORY,
                            bytes32(0),
                            keccak256(
                                abi.encodePacked(
                                    type(OpSenderProxy).creationCode,
                                    abi.encode(
                                        senderProxy_opCrossDomainMessenger,
                                        senderProxy_receiverChainId,
                                        senderProxy_hyperlaneMailbox
                                    )
                                )
                            )
                        )
                    )
                )
            )
        );

        // Load constructor parameters for `OpReceiverProxy`
        address receiverProxy_opCrossDomainMessenger = vm.envAddress(
            "RECEIVER_PROXY_OP_CROSS_DOMAIN_MESSENGER"
        );
        uint32 receiverProxy_senderChainId = uint32(
            vm.envUint("RECEIVER_PROXY_SENDER_CHAIN_ID")
        );
        address receiverProxy_hyperlaneMailbox = vm.envAddress(
            "RECEIVER_PROXY_HYPERLANE_MAILBOX"
        );
        uint256 receiverProxy_feeBps = vm.envUint("RECEIVER_PROXY_FEE_BPS");

        // Deploy `OpReceiverProxy`
        OpReceiverProxy opReceiverProxy = new OpReceiverProxy{salt: bytes32(0)}(
            receiverProxy_opCrossDomainMessenger,
            receiverProxy_senderChainId,
            receiverProxy_hyperlaneMailbox,
            receiverProxy_feeBps,
            predictedSenderProxyAddress
        );

        console2.log("OpReceiverProxy deployed at ", address(opReceiverProxy));

        vm.stopBroadcast();
    }
}
