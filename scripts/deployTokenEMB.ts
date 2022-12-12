import { ethers } from "hardhat";

const OWNER_ADDRESS = process.env.OWNER_ADDRESS!;

async function main() {
  console.log("Deploying TokenEMB contract with the account:", OWNER_ADDRESS);

  const Token = await ethers.getContractFactory("TokenEMB");
  const token = await Token.deploy("Token EMB", "EMB");

  await token.deployed();
  console.log("TokenEMB contract deployed to:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
