//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./TokenEMB.sol";

contract Protocol is Ownable {
    /* ======================= EVENTS ======================= */

    event AirdropProcessed(address recipient, uint256 amount, uint256 ts);

    /* ======================= PUBLIC STATE VARS ======================= */

    /**
     * @notice ERC20 token address instance
     */
    address public immutable token;

    /**
     * @notice max total airdrop tokens allowed in one mint
     */
    uint256 public maxTokensNoPerMint;

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

    /* ======================= CONSTRUCTOR ======================= */

    constructor(
        address signer,
        address _token,
        uint256 maxTokenMintNo,
        uint256 _maxTokensNoPerMint
    ) {
        _signer = signer;
        token = _token;
        _maxTokenMintNo = maxTokenMintNo;
        _tokenMintCount = 0;
        maxTokensNoPerMint = _maxTokensNoPerMint;

        DOMAIN_SEPARATOR = hashDomain(
            EIP712Domain({
                name: "Airdrop",
                version: "1",
                chainId: block.chainid,
                verifyingContract: address(this)
            })
        );
    }

    // Allowlist addresses
    function recoverSigner(bytes32 hash, bytes memory signature)
        public
        pure
        returns (address)
    {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function claimAirdrop(
        address _minter,
        uint256 _amount,
        bytes32 hash,
        bytes calldata signature
    ) public {
        require(
            recoverSigner(hash, signature) == _signer,
            "Address is not allowlisted"
        );
        require(!_signatureUsed[signature], "Signature has already been used");
        require(_tokenMintCount <= _maxTokenMintNo, "Airdrop: maxed supply");
        require(
            _amount <= maxTokensNoPerMint,
            "Airdrop: exceeded token amount per mint"
        );

        _mint(_minter, _amount);

        _signatureUsed[signature] = true;

        emit AirdropProcessed(_minter, _amount, block.timestamp);
    }

    /* ======================= INTERNAL FUNCTIONS ======================= */

    function _mint(address _minter, uint256 _amount) private {
        TokenEMB(token).mint(_minter, _amount);
        _tokenMintCount += _amount;
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
