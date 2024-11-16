// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IOpCrossDomainMessenger} from "../../src/interfaces/IOpCrossDomainMessenger.sol";

contract OpCrossDomainMessengerMock is IOpCrossDomainMessenger {
    function sendMessage(
        address, // target
        bytes calldata, // message
        uint32 // minGasLimit
    ) external payable {
        // Do nothing
    }
}
