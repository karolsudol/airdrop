//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./TokenEMB.sol";

contract ProtocolPersonalSign is Ownable {
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

        emit AirdropProcessed(msg.sender, _amount, block.timestamp);
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
}
