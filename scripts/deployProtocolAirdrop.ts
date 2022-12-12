import { ethers } from "hardhat";

const OWNER_ADDRESS = process.env.OWNER_ADDRESS!;
const VALIDATOR_ADDRESS: string = process.env.VALIDATOR_ADDRESS!;
const TOKEN_EMB_ADDRESS: string = process.env.TOKEN_EMB_ADDRESS_GOERLI!;
const EIP712_ADDRESS_GOERLI: string = process.env.EIP712_ADDRESS_GOERLI!;

const MAX_SUPPLY = 100 * 10 ** 18;
const MAX_PER_MINT = 10 * 10 ** 18;

const chainID = 5;

async function main() {
  console.log(
    "Deploying Protocol Airdrop contract with the account:",
    OWNER_ADDRESS
  );

  const Bridge = await ethers.getContractFactory("ProtocolAirdrop", {
    libraries: {
      ProtocolEIP712: EIP712_ADDRESS_GOERLI,
    },
  });
  const bridge = await Bridge.deploy(
    VALIDATOR_ADDRESS,
    TOKEN_EMB_ADDRESS,
    MAX_SUPPLY.toString(),
    MAX_PER_MINT.toString()
  );

  await bridge.deployed();
  console.log("Protocol Airdrop  contract deployed to:", bridge.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
