// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IHyperlaneMailbox {
    function dispatch(
        uint32 receiverChainId,
        bytes32 receiverAddress,
        bytes calldata data
    ) external payable returns (bytes32 id);

    function quoteDispatch(
        uint32 receiverChainId,
        bytes32 receiverAddress,
        bytes calldata data
    ) external returns (uint256 fee);
}
