//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Protocol
 * @notice A contract for minting EMB token which allows minters to mint their tokens using signatures.
 *
 */
contract Airdrop is Ownable {
    /* ======================= EVENTS ======================= */

    event Minted(address recipient, uint256 amount, uint256 ts);

    /* ======================= STATE VARS ======================= */

    /**
    @notice Record of already-used signatures.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
     * @notice A mapping to keep track of which addresses have already minted their airdrop
     */
    mapping(address => bool) public alreadyMinted;

    /**
     * @notice A var to keep track of already minted  airdrop tokens
     */
    uint256 public currentMintedAmount;

    /**
     * @notice max total airdrop tokens allowed
     */
    uint256 public maxAmountMinted;

    /**
     * @notice The address whose private key will create all the signatures which minters can use to mint their EMB tokens
     */
    address public immutable signer;

    /**
     * @notice EMB ERC20 token address instance
     */
    IERC20 public immutable EMBToken;

    /**
     * @notice the EIP712 domain separator for minting EMB
     */
    bytes32 public immutable EIP712_DOMAIN;

    /**
     * @notice EIP-712 typehash for minting EMB
     */
    bytes32 public constant SUPPORT_TYPEHASH =
        keccak256("Mint(address minter,uint256 amount)");

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    /* ======================= EIP712 ======================= */

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /* ======================= CONSTRUCTOR ======================= */

    /**
     * @notice Sets the necessary initial minter verification data
     *
     * @param _signer address of the off chain signer worker
     * @param _EMBToken instance of the EMBToken that will be minted
     * @param _maxAmountMinted total mintalble amount allocated to the airdrop
     *
     * @dev `EIP712_DOMAIN` and `NOT_ENTERED` reentrancy status are also set here.
     */
    constructor(
        address _signer,
        IERC20 _EMBToken,
        uint256 _maxAmountMinted
    ) {
        signer = _signer;
        EMBToken = _EMBToken;
        maxAmountMinted = _maxAmountMinted;

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

        _status = _NOT_ENTERED;
    }

    /* ======================= MODIFIERS ======================= */

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "Airdrop: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /* ======================= VIEW FUNCTIONS ======================= */

    /* ======================= EXTERNAL FUNCTIONS ======================= */

    /**
     * @notice Allows a msg.sender to mint their EMB token by providing a signature is signed by the `Protocol.signer` address.
     *
     * @param signature An array of bytes representing a signature created by the  `Protocol.signer` address
     * @param _to The address the minted EMB should be sent to
     *
     * @dev See `Protocol.toTypedDataHash` for how to format the pre-signed data
     * @dev An address can only mint its EMB once
     *
     */
    function signatureMint(bytes calldata signature, address _to)
        external
        nonReentrant
    {
        // TODO implement me!
    }

    /* ======================= EXTERNAL FUNCTIONS ======================= */

    /**
     * @dev Helper function for formatting the minter data in an EIP-712 compatible way
     *
     * @param _minter The address which will mint the EMB tokens
     * @param _amount The amount of EMB to be minted
     *
     * @return A 32-byte hash, which will have been signed by `Protocol.signer`
     */
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
}
