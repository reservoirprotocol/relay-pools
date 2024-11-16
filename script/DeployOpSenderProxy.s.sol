pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {OpSenderProxy} from "../src/OpSenderProxy.sol";

contract DeployOpSenderProxy is Script {
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

        // Deploy `OpSenderProxy`
        OpSenderProxy opSenderProxy = new OpSenderProxy{salt: bytes32(0)}(
            senderProxy_opCrossDomainMessenger,
            senderProxy_receiverChainId,
            senderProxy_hyperlaneMailbox
        );

        console2.log("OpSenderProxy deployed at ", address(opSenderProxy));

        vm.stopBroadcast();
    }
}
