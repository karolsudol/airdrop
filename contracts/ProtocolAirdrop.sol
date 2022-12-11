//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./TokenEMB.sol";

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

    /**
     * @notice Sets the necessary initial minter verification data
     *
     * @param signer address of the off chain signer worker
     * @param _token instance of the EMBToken that will be minted
     * @param maxTokenMintNo total mintalble amount allocated to the whole airdrop
     * @param _maxTokensNoPerMint max amount to mint per one airdrop
     *
     * @dev `EIP712_DOMAIN` and `NOT_ENTERED` reentrancy status are also set here.
     */
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

    /* ======================= MODIFIERS ======================= */

    /**
     *  @dev Prevents from exceeding total airdrop allowance
     */
    modifier maxMinted() {
        require(_tokenMintCount <= _maxTokenMintNo, "Airdrop: maxed supply");
        _;
    }

    /* ======================= PUBLIC FUNCTIONS ======================= */

    /**
     * @notice Allows a msg.sender to mint their EMB token by providing a signature is signed by the `Protocol.signer` address.
     *
     * @param _minter an address where tokens will be minted to
     * @param _amount the value of ERC20 token in 18 dec to be minted
     * @param signature An array of bytes representing a signature created by the  `Airdrop.signer` address
     *
     */
    function claimAirdrop(
        address _minter,
        uint256 _amount,
        bytes calldata signature
    ) public maxMinted {
        require(
            _verify(_hash(_minter, _amount), signature),
            "Airdrop: Invalid signature"
        );

        require(
            !_signatureUsed[signature],
            "Airdrop: Signature has already been used"
        );

        require(
            _amount <= maxTokensNoPerMint,
            "Airdrop: exceeded token amount per mint"
        );

        _mint(_minter, _amount);

        _signatureUsed[signature] = true;
        _tokenMintCount += _amount;

        emit AirdropProcessed(msg.sender, _amount);
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
     * @dev hashes message
     *
     * @param account The address which will mint the EMB tokens
     * @param amount The amount of EMB to be minted
     *
     */
    function _hash(address account, uint256 amount)
        internal
        pure
        returns (bytes32)
    {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(account, amount))
            );
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
}
