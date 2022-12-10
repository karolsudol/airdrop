import { ethers } from "hardhat";

const OWNER_ADDRESS = process.env.OWNER_ADDRESS!;

async function main() {
  const allowlistedAddresses = [
    "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
    "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc",
    "0x90f79bf6eb2c4f870365e785982e1f101e93b906",
    "0x15d34aaf54267db7d7c367839aaf71a00a2c6a65",
    "0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc",
  ];
  //   console.log("Deploying TokenERC20 contract with the account:", OWNER_ADDRESS);

  //   const Token = await ethers.getContractFactory("TokenERC20");
  //   const token = await Token.deploy("TokenERC20", "TKN");

  //   await token.deployed();
  //   console.log("Token contract deployed to:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
