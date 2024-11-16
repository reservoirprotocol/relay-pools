pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {OpSenderProxy} from "../src/OpSenderProxy.sol";

contract Withdraw is Script {
    function run() public {
        vm.startBroadcast();

        // Load parameters
        address senderProxy = vm.envAddress("SENDER_PROXY");
        address receiverProxy = vm.envAddress("RECEIVER_PROXY");
        address withdrawTo = vm.envAddress("WITHDRAW_TO");
        uint256 withdrawAmount = vm.envUint("WITHDRAW_AMOUNT");

        OpSenderProxy(senderProxy).withdraw{value: withdrawAmount}(
            withdrawTo,
            receiverProxy
        );

        console2.log("Successfully triggered withdrawal");

        vm.stopBroadcast();
    }
}
