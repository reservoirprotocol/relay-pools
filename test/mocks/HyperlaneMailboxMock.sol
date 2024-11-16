// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IHyperlaneMailbox} from "../../src/interfaces/IHyperlaneMailbox.sol";

contract HyperlaneMailboxMock is IHyperlaneMailbox {
    function dispatch(
        uint32, // receiverChainId
        bytes32, // receiverAddress
        bytes calldata // data
    ) external payable returns (bytes32 id) {
        return bytes32(block.number);
    }

    function quoteDispatch(
        uint32, // receiverChainId
        bytes32, // receiverAddress
        bytes calldata // data
    ) external pure returns (uint256 fee) {
        return 0.001 ether;
    }
}
