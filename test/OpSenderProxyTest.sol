pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";

import {HyperlaneMailboxMock} from "./mocks/HyperlaneMailboxMock.sol";
import {OpCrossDomainMessengerMock} from "./mocks/OpCrossDomainMessengerMock.sol";
import {OpSenderProxy} from "../src/OpSenderProxy.sol";
import {IHyperlaneMailbox} from "../src/interfaces/IHyperlaneMailbox.sol";
import {IOpCrossDomainMessenger} from "../src/interfaces/IOpCrossDomainMessenger.sol";

contract OpSenderProxyTest is Test {
    address public user;

    IOpCrossDomainMessenger public opCrossDomainMessenger;
    IHyperlaneMailbox public hyperlaneMailbox;

    uint32 public receiverChainId;
    address public opReceiverProxy;

    OpSenderProxy public opSenderProxy;

    function setUp() public {
        user = address(1);
        vm.deal(user, 1000 ether);

        opCrossDomainMessenger = new OpCrossDomainMessengerMock();
        hyperlaneMailbox = new HyperlaneMailboxMock();

        receiverChainId = 1;
        opReceiverProxy = address(2);

        opSenderProxy = new OpSenderProxy(
            address(opCrossDomainMessenger),
            receiverChainId,
            address(hyperlaneMailbox)
        );
    }

    function test_withdraw() public {
        uint256 amount = 1 ether;

        vm.prank(user);
        opSenderProxy.withdraw{value: amount}(user, opReceiverProxy);
    }
}
