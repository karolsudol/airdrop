//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";

/**
 * @title Airdrop
 *
 * @notice A contract allows minters to mint their ERC20 tokens using eip-712 signatures verification.
 *
 * @dev https://github.com/ethereum/EIPs/blob/master/assets/eip-712
 */
contract Airdrop is Ownable {
    /* ======================= EVENTS ======================= */

    event AirdropProcessed(address recipient, uint256 amount, uint256 ts);

    /* ======================= PUBLIC STATE VARS ======================= */

    /**
     * @notice Record of already-used signatures.
     */
    mapping(bytes => bool) public usedMessages;

    /**
     * @notice A mapping to keep track of which addresses have already minted their airdrop
     */
    mapping(address => bool) public airdrops;

    /**
     * @notice A var to keep track of already minted  airdrop tokens
     */
    uint256 public supply;

    /**
     * @notice max total airdrop tokens allowed
     */
    uint256 public maxSupply;

    /**
     * @notice max total airdrop tokens allowed in one mint
     */
    uint256 public maxPerMint;

    /* ======================= CONST PRIVATE RE-ENTTANCE VARS ======================= */

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    /* ======================= CONST PUBLIC VARS ======================= */

    /**
     * @notice The address whose private key will create all the signatures which minters can use to mint their EMB tokens
     */
    address public immutable signer;

    /**
     * @notice ERC20 token address instance
     */
    address public immutable token;

    /* ======================= EIP-712 - DOMAIN ======================= */

    /**
     * @notice EIP712 domain structure
     */
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    /**
     * @notice the EIP712 domain separator for minting EMB
     */
    bytes32 public immutable DOMAIN_SEPARATOR;

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /* ======================= EIP-712 - MINT ======================= */

    /**
     * @notice EIP712 minting msg data structure
     */
    struct Mint {
        address minter;
        uint256 amount;
    }

    /**
     * @notice EIP-712 typehash for minting token
     */
    bytes32 public constant MINT_TYPEHASH =
        keccak256("Mint(address minter,uint256 amount)");

    /* ======================= CONSTRUCTOR ======================= */

    /**
     * @notice Sets the necessary initial minter verification data
     *
     * @param _signer address of the off chain signer worker
     * @param _token instance of the EMBToken that will be minted
     * @param _maxSupply total mintalble amount allocated to the whole airdrop
     * @param _maxPerMint max amount to mint per one airdrop
     *
     * @dev `EIP712_DOMAIN` and `NOT_ENTERED` reentrancy status are also set here.
     */
    constructor(
        address _signer,
        address _token,
        uint256 _maxSupply,
        uint256 _maxPerMint
    ) {
        signer = _signer;
        token = _token;
        maxSupply = _maxSupply;
        supply = 0;
        maxPerMint = _maxPerMint;

        DOMAIN_SEPARATOR = hashDomain(
            EIP712Domain({
                name: "Airdrop",
                version: "1",
                chainId: block.chainid,
                verifyingContract: address(this)
            })
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

    /**
     *  @dev Prevents an address from multiple claims
     */
    modifier claimed() {
        require(airdrops[msg.sender] == false, "Airdrop: user claimed");
        _;
    }

    /**
     *  @dev Prevents from exceeding total airdrop allowance
     */
    modifier maxMinted() {
        require(maxSupply < supply, "Airdrop: max supply");
        _;
    }

    /* ======================= VIEW FUNCTIONS ======================= */

    /* ======================= EXTERNAL FUNCTIONS ======================= */

    /**
     * @notice Allows a msg.sender to mint their EMB token by providing a signature is signed by the `Protocol.signer` address.
     *
     * @param signature An array of bytes representing a signature created by the  `Airdrop.signer` address
     *
     * @dev See `Protocol.toTypedDataHash` for how to format the pre-signed data
     * @dev An address can only mint its token and only once
     *
     */
    function signatureMint(bytes calldata signature, uint256 amount)
        external
        maxMinted
        nonReentrant
        claimed
    {
        require(amount <= maxPerMint, "Airdrop: max mint amount");
        require(signature.length == 65, "Airdrop: invalid signature length");
        require(usedMessages[signature] == false, "Airdrop: signature used");

        Mint memory mint;
        mint = Mint(msg.sender, amount);

        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature);

        require(verify(mint, v, r, s), "Airdrop: invalid signature");

        // require(usedMessages[signature] == chainId, "Airdrop: invalid chainId");

        Token(token).mint(msg.sender, amount);

        airdrops[msg.sender] = true;
        usedMessages[signature] = true;

        emit AirdropProcessed(msg.sender, amount, block.timestamp);
    }

    /* ======================= INTERNAL FUNCTIONS ======================= */

    function hashDomain(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function hashMint(Mint memory mint) internal pure returns (bytes32) {
        return keccak256(abi.encode(MINT_TYPEHASH, mint.minter, mint.amount));
    }

    function verify(
        Mint memory mint,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashMint(mint))
        );
        return signer == ecrecover(digest, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

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
            abi.encode(EIP712DOMAIN_TYPEHASH, _minter, _amount)
        );
        return ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);
    }
}
