//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/// @title Protocol
/// @author kadro
/// @notice A contract for minting EMB token which allows minters to mint
/// their tokens using signatures.
contract Protocol is Ownable {
    /// @notice Address of the EMB ERC20 token
    IERC20 public immutable EMBToken;

    /**
    @dev Record of already-used signatures.
     */
    mapping(bytes32 => bool) public usedMessages;

    /// @notice The address whose private key will create all the signatures which minters
    /// can use to mint their EMB tokens
    address public immutable signer;

    /// @notice A mapping to keep track of which addresses
    /// have already minted their airdrop
    mapping(address => bool) public alreadyMinted;

    /// @notice the EIP712 domain separator for minting EMB
    bytes32 public immutable EIP712_DOMAIN;

    /// @notice EIP-712 typehash for minting EMB
    bytes32 public constant SUPPORT_TYPEHASH =
        keccak256("Mint(address minter,uint256 amount)");

    /// @notice Sets the necessary initial minter verification data
    constructor(address _signer, IERC20 _EMBToken) {
        signer = _signer;
        EMBToken = _EMBToken;

        EIP712_DOMAIN = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Protocol")),
                keccak256(bytes("v1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice Allows a msg.sender to mint their EMB token by providing a
    /// signature signed by the `Protocol.signer` address.
    /// @dev An address can only mint its EMB once
    /// @dev See `Protocol.toTypedDataHash` for how to format the pre-signed data
    /// @param signature An array of bytes representing a signature created by the
    /// `Protocol.signer` address
    /// @param _to The address the minted EMB should be sent to
    function signatureMint(bytes calldata signature, address _to) external {
        // TODO implement me!
    }

    /// @dev Helper function for formatting the minter data in an EIP-712 compatible way
    /// @param _minter The address which will mint the EMB tokens
    /// @param _amount The amount of EMB to be minted
    /// @return A 32-byte hash, which will have been signed by `Protocol.signer`
    function toTypedDataHash(address _minter, uint256 _amount)
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(
            abi.encode(SUPPORT_TYPEHASH, _minter, _amount)
        );
        return ECDSA.toTypedDataHash(EIP712_DOMAIN, structHash);
    }

    event minted(address minter);
}
