# AIRDROP

ECDSA and EIP-712 signatures dependent ERC20 token airdrop.

Instead of minting and distributing all the tokens in a single transaction (which might not be possible if the number of minters is large), the Protocol authenticate minters using ECDSA and EIP712 - structured signatures

## Flow

1. Create a centralized server and database that holds all the addresses that are allowlisted.
2. When a wallet tries to initiate a mint of the airdrops protocol, send the wallet address to the server.
3. The server checks if the address has been allowlisted and if it has, it signs the wallet address with a private key that is known only to the project’s creator.
4. The server returns the signed message to the client (or website) and this in turn, is sent to the smart contract.
5. The contract’s mint function verifies that the message sent was indeed signed by the wallet controlled by the owner. If the verification succeeds, minting is allowed.
6. The signed message is stored in a mapping to prevent it from being used more than once or by multiple wallets.

## ProtocolAirdrop Contract

1. is deployed with:

   - hardcoded with non changable signer and ERC20 token
   - max airdrop supply allowed
   - max token units per drop

2. requires owner's right to be granted by the TokenEMB contracts owner - in order to mint
3. mints token using either valid `ECDSA` (covered inside the contract) or `EIP-712` (with ProtocolEIP712 lib) signatures

## Usage

```
npm install hardhat
REPORT_GAS=true npx hardhat test
npx hardhat coverage

npx hardhat run --network goerli scripts/deployTokenEMB.ts
 npx hardhat verify --network goerli 0x672A5D9a7BB38592A163c591dc10E4410C1959A0 "Token EMB" "EMB"

npx hardhat run --network goerli scripts/deployProtocolEIP712.ts
npx hardhat verify --network goerli 0x032c0E85Bd37CFA30E35b1B2Ac98322D8bF42D2B

npx hardhat run --network goerli scripts/deployProtocolAirdrop.ts
npx hardhat verify --network goerli --libraries library.ts 0xb5e79d544Dc8dE31991Ac395027E62B3dD43C028 "0x698b03E5F2e3b9D0eAF6f142468817bA1259c885" "0x672A5D9a7BB38592A163c591dc10E4410C1959A0" "100000000000000000000" "10000000000000000000"
 9288
```

## Deployed on Goerli

- `TokenEMB` Deployed and Verified on [goerli](https://goerli.etherscan.io/address/0x672A5D9a7BB38592A163c591dc10E4410C1959A0#code)
- `ProtocolAirdrop` Deployed and Verified on [goerli](https://goerli.etherscan.io/address/0xb5e79d544Dc8dE31991Ac395027E62B3dD43C028#code)
- `ProtocolEIP712` Deployed and Verified on [goerli](https://goerli.etherscan.io/address/0x032c0E85Bd37CFA30E35b1B2Ac98322D8bF42D2B#code)

- with [owner](https://goerli.etherscan.io/address/0x1f190F523deBD185183d8Afe76e4587a08bb84e7)
- with [signer](https://goerli.etherscan.io/address/0x698b03E5F2e3b9D0eAF6f142468817bA1259c885)

## coverage

<br/>
<p align="center">
<img src="img/coverage.png">
</a>
</p>
<br/>

## TODO

1. test zero contract signer attack
2. test re-entrancy attack
3. add Merkle Proof validation library
