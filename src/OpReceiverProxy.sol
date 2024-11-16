// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "solady/tokens/ERC20.sol";

import {IHyperlaneMailbox} from "./interfaces/IHyperlaneMailbox.sol";

import {Utils} from "./Utils.sol";

contract OpReceiverProxy is ERC20, Utils {
    // Errors

    error Unauthorized();

    // Constants

    address public immutable OP_CROSS_DOMAIN_MESSENGER;
    uint32 public immutable SENDER_CHAIN_ID;
    address public immutable HYPERLANE_MAILBOX;
    uint256 public immutable FEE_BPS;

    // Public fields

    address public opSenderProxy;
    mapping(uint256 => bool) public idWasUsed;
    mapping(address => uint256) public balances;

    // Constructor

    constructor(
        address _opCrossDomainMesenger,
        uint32 _senderChainId,
        address _hyperlaneMailbox,
        uint256 _feeBps,
        address _opSenderProxy
    ) {
        OP_CROSS_DOMAIN_MESSENGER = _opCrossDomainMesenger;
        SENDER_CHAIN_ID = _senderChainId;
        HYPERLANE_MAILBOX = _hyperlaneMailbox;
        FEE_BPS = _feeBps;

        opSenderProxy = _opSenderProxy;
    }

    // ERC20 overrides

    function name() public pure override returns (string memory) {
        return "Relay ETH";
    }

    function symbol() public pure override returns (string memory) {
        return "RETH";
    }

    // Public methods

    /**
     * @notice Deposit funds into the pool
     *
     * @param to Address to deposit on behalf of
     */
    function deposit(address to) external payable {
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = msg.value;
        } else {
            shares = (msg.value * totalSupply()) / address(this).balance;
        }

        // Mint shares
        _mint(to, shares);
    }

    /**
     * @notice Withdraw funds from the pool
     *
     * @param shares Amount of pool shares to withdraw
     */
    function withdraw(uint256 shares) public {
        uint256 amount = (address(this).balance * shares) / totalSupply();

        // Burn shares
        _burn(msg.sender, amount);

        // Send the corresponding funds back to the user
        _send(msg.sender, amount);
    }

    /**
     * @notice Withdraw everything a particular user owns from the pool
     */
    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    // Restricted methods

    /**
     * @notice Hyperlane message-receiving hook
     *
     * @dev Only the Hyperlane Mailbox contract can call this method
     *
     * @param senderChainId The chain id where the message is originating from
     * @param senderAddress The address of the sender on the origin chain
     * @param data The message data
     */
    function handle(
        uint32 senderChainId,
        bytes32 senderAddress,
        bytes calldata data
    ) external {
        // Only `HYPERLANE_MAILBOX` is authorized to call this method
        if (msg.sender != HYPERLANE_MAILBOX) {
            revert Unauthorized();
        }

        // The sender chain must be `SENDER_CHAIN_ID`
        if (senderChainId != SENDER_CHAIN_ID) {
            revert Unauthorized();
        }

        // The sender address must be `opSenderProxy`
        if (senderAddress != bytes32(uint256(uint160(opSenderProxy)))) {
            revert Unauthorized();
        }

        // Parse the data received from the sender chain
        (uint256 id, address to, uint256 amount) = abi.decode(
            data,
            (uint256, address, uint256)
        );

        // If the parsed id was not already used then we simply forward the received funds to the parsed recipient
        if (!idWasUsed[id]) {
            // This was a fast bridge, so take the fee out of the amount
            _send(to, amount - (amount * FEE_BPS) / 1e18);

            // Mark the id as being used
            idWasUsed[id] = true;
        }
    }

    /**
     * @notice Fallback method
     *
     * @dev Only the predefined OP xDomain Messenger contract can call this method
     */
    fallback() external payable {
        // Only `OP_CROSS_DOMAIN_MESSENGER` is authorized to call this
        if (msg.sender != OP_CROSS_DOMAIN_MESSENGER) {
            revert Unauthorized();
        }

        // Parse the data received from the sender chain
        (uint256 id, address to) = abi.decode(msg.data, (uint256, address));

        // If the parsed id was not already used then we simply forward the received funds to the parsed recipient
        if (!idWasUsed[id]) {
            // This was a slow bridge, so no fee is taken out of the amount
            _send(to, msg.value);

            // Mark the id as being used
            idWasUsed[id] = true;
        }
    }
}
