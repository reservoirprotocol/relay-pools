pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";

import {HyperlaneMailboxMock} from "./mocks/HyperlaneMailboxMock.sol";
import {OpReceiverProxy} from "../src/OpReceiverProxy.sol";
import {IHyperlaneMailbox} from "../src/interfaces/IHyperlaneMailbox.sol";

contract OpReceiverProxyTest is Test {
    address public user;

    IHyperlaneMailbox public hyperlaneMailbox;

    address public opCrossDomainMessenger;
    uint32 public senderChainId;
    uint256 public feeBps;
    address public opSenderProxy;

    OpReceiverProxy public opReceiverProxy;

    function setUp() public {
        user = address(1);
        vm.deal(user, 1000 ether);

        hyperlaneMailbox = new HyperlaneMailboxMock();

        opCrossDomainMessenger = address(1);
        senderChainId = 1;
        feeBps = 5e15;
        opSenderProxy = address(2);

        opReceiverProxy = new OpReceiverProxy(
            opCrossDomainMessenger,
            senderChainId,
            address(hyperlaneMailbox),
            feeBps,
            opSenderProxy
        );
    }

    function test_handle() public {
        uint256 amount = 1 ether;

        vm.deal(address(opReceiverProxy), 10 ether);

        uint256 balanceBefore = user.balance;

        vm.prank(address(hyperlaneMailbox));
        opReceiverProxy.handle(
            senderChainId,
            bytes32(uint256(uint160(opSenderProxy))),
            abi.encode(0, user, amount)
        );

        uint256 balanceAfter = user.balance;

        assertEq(
            balanceAfter - balanceBefore,
            amount - (amount * opReceiverProxy.FEE_BPS()) / 1e18
        );
    }

    function test_onlyHyperlaneMailboxCanHandle() public {
        vm.prank(user);
        vm.expectRevert(OpReceiverProxy.Unauthorized.selector);
        opReceiverProxy.handle(
            senderChainId,
            bytes32(uint256(uint160(opSenderProxy))),
            abi.encode(0, user, 1 ether)
        );
    }
}
