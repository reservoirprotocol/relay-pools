// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IOpCrossDomainMessenger {
    function sendMessage(
        address target,
        bytes calldata message,
        uint32 minGasLimit
    ) external payable;
}
