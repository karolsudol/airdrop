import { ethers } from "hardhat";

const OWNER_ADDRESS = process.env.OWNER_ADDRESS!;

async function main() {
  console.log(
    "Deploying ProtocolEIP712 contract with the account:",
    OWNER_ADDRESS
  );

  const Token = await ethers.getContractFactory("ProtocolEIP712");
  const token = await Token.deploy();

  await token.deployed();
  console.log("ProtocolEIP712 contract deployed to:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
