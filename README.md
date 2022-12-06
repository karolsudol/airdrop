# AIRDROP

ECDSA signature dependent airdrop of EMB ERC20 token contract.

##

Instead of minting and distributing all the tokens in a single transaction (which might not be possible if the number of minters is large), the Protocol authenticate minters using ECDSA signatures

## Usage

```
npm install hardhat
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat node
npx hardhat run scripts/deploy.ts
```
