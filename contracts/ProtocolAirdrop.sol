//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ProtocolEIP712.sol";
import "./TokenEMB.sol";

// import "@contracts/ProtocolEIP712.sol";

contract ProtocolAirdrop is Ownable {
    /* ======================= EVENTS ======================= */

    event AirdropProcessed(address recipient, uint256 amount);

    /* ======================= PUBLIC STATE VARS ======================= */

    /**
     * @notice ERC20 token address instance
     */
    address public immutable token;

    /**
     * @notice max total airdrop tokens allowed in one mint
     */
    uint256 public maxTokensNoPerMint;

    /**
     * @notice merkle tree root to verify minter - defined in constructor
     */
    // bytes32 public immutable root;

    /* ======================= PRIVATE STATE VARS ======================= */

    /**
     * @notice A var to keep track of already minted  airdrop tokens
     */
    uint256 private _tokenMintCount;

    /**
     * @notice max total airdrop tokens allowed
     */
    uint256 private _maxTokenMintNo;

    /**
     * @notice Record of already-used signatures.
     */
    mapping(bytes => bool) private _signatureUsed;

    /**
     * @notice The address whose private key will create all the signatures which minters can use to mint their EMB tokens
     */
    address private immutable _signer;

    /* ======================= CONST PRIVATE RE-ENTTANCE VARS ======================= */

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    // * ======================= EIP712 DOMAIN ======================= */

    /**
     * @notice the EIP712 domain separator for minting EMB
     */
    bytes32 public immutable DOMAIN_SEPARATOR;

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    function hash(EIP712Domain memory eip712Domain)
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

    /* ======================= CONSTRUCTOR ======================= */

    /**
     * @notice Sets the necessary initial minter verification data
     *
     * @param signer address of the off chain signer worker
     * @param _token instance of the EMBToken that will be minted
     * @param maxTokenMintNo total mintalble amount allocated to the whole airdrop
     * @param _maxTokensNoPerMint max amount to mint per one airdrop
     *
     *  root of a merkle tree to calculate leafs hashes for signing messages
     *
     * @dev `EIP712_DOMAIN` and `NOT_ENTERED` reentrancy status are also set here.
     */
    constructor(
        address signer,
        address _token,
        uint256 maxTokenMintNo,
        uint256 _maxTokensNoPerMint // bytes32 merkleroot
    ) {
        _signer = signer;
        token = _token;
        _maxTokenMintNo = maxTokenMintNo;
        _tokenMintCount = 0;
        maxTokensNoPerMint = _maxTokensNoPerMint;

        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: "Airdrop",
                version: "1",
                chainId: block.chainid,
                verifyingContract: address(this)
            })
        );
        // root = merkleroot;
    }

    /* ======================= MODIFIERS ======================= */

    /**
     *  @dev Prevents from exceeding total airdrop allowance
     */
    modifier maxMinted() {
        require(_tokenMintCount <= _maxTokenMintNo, "Airdrop: maxed supply");
        _;
    }

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

    /* ======================= PUBLIC FUNCTIONS ======================= */

    /**
     * @notice Allows a msg.sender to mint their EMB token by providing a signature is signed by the `Protocol.signer` address.
     *
     * @param minter an address where tokens will be minted to
     * @param amount the value of ERC20 token in 18 dec to be minted
     * @param signature An array of bytes representing a signature created by the  `Airdrop.signer` address
     *
     */
    function claimAirdrop(
        address minter,
        uint256 amount,
        bytes calldata signature
    ) public maxMinted nonReentrant {
        Mint memory mint;
        mint.amount = amount;
        mint.minter = minter;

        require(signature.length == 65, "Airdrop: invalid signature length");

        require(
            (_verify(_hashMsg(minter, amount), signature) ||
                ProtocolEIP712.verify(mint, address(this), _signer, signature)),
            "Airdrop: Invalid signature"
        );

        require(
            !_signatureUsed[signature],
            "Airdrop: Signature has already been used"
        );

        require(
            amount <= maxTokensNoPerMint,
            "Airdrop: exceeded token amount per mint"
        );

        _mint(minter, amount);

        _signatureUsed[signature] = true;
        _tokenMintCount += amount;

        emit AirdropProcessed(minter, amount);
    }

    /* ======================= INTERNAL FUNCTIONS ======================= */

    /**
     * @dev mints ERC20 Token via Token
     *
     * @param _minter The address which will mint the EMB tokens
     * @param _amount The amount of EMB to be minted
     *
     */
    function _mint(address _minter, uint256 _amount) private {
        TokenEMB(token).mint(_minter, _amount);
        _tokenMintCount += _amount;
    }

    /**
     * @dev verifies whether designated signer signed the messgae
     *
     * @param digest message in bytes
     * @param signature signed message
     *
     */
    function _verify(bytes32 digest, bytes memory signature)
        internal
        view
        returns (bool)
    {
        address _signerRecovered = ECDSA.recover(digest, signature);
        if (_signer == _signerRecovered) {
            return true;
        } else {
            return false;
        }
    }

    /* ======================= HASH FUNCTIONS ======================= */

    /**
     * @dev hashes message
     *
     * @param minter The address which will mint the EMB tokens
     * @param amount The amount of EMB to be minted
     *
     */
    function _hashMsg(address minter, uint256 amount)
        internal
        pure
        returns (bytes32)
    {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(minter, amount))
            );
    }

    /* ======================= MERKLE PROOF ======================= */

    // function _leaf(address minter, uint256 amount)
    //     internal
    //     pure
    //     returns (bytes32)
    // {
    //     return keccak256(abi.encodePacked(minter, amount));
    // }

    // function _verifyMerkleProof(bytes32 leaf, bytes32[] memory proof)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return MerkleProof.verify(proof, root, leaf);
    // }
}
