//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
 * @notice EIP712 minting msg data structure
 */
struct Mint {
    address minter;
    uint256 amount;
}

library ProtocolEIP712 {
    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 constant MINT_TYPEHASH =
        keccak256("Mint(address minter,uint256 amount)");

    function verify(
        Mint memory mint,
        address verifyingContract,
        address authorizedSigner,
        bytes memory signature
    ) external view returns (bool) {
        // uint256 chainId;
        // assembly {
        //     chainId := chainid()
        // }
        bytes32 domainSeperator = hashDomain(
            EIP712Domain({
                name: "Airdrop",
                version: "1",
                chainId: 51,
                verifyingContract: verifyingContract
            })
        );
        address signer = recoverSigner(mint, domainSeperator, signature);
        if (signer != authorizedSigner) {
            revert("EIP712: unauthorized signer");
        }
        return true;
    }

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

    function digest(Mint memory mint, bytes32 domainSeparator)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, hashMint(mint))
            );
    }

    function recoverSigner(
        Mint memory mint,
        bytes32 domainSeparator,
        bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        address signer = ecrecover(digest(mint, domainSeparator), v, r, s);
        if (signer == address(0)) {
            revert("EIP712: zero address");
        }
        return signer;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "EIP712: invalid signature length");
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
        return (r, s, v);
    }
}
