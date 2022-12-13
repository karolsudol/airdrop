import { ethers } from "hardhat";
import { Wallet } from "ethers";
import * as dotenv from "dotenv";
import { task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-ethers";
// import hash from "../scripts/hash";
// import { hash } from "./scripts";

dotenv.config();

const privateKey = process.env.PRIVATE_KEY_SIGNER!;

// task("signature", "signer generates signature'")
//   .addParam("account", "minters's account")
//   .addParam("amount", "erc20 emb token amount")
//   .setAction(async (taskArgs: { amount: any; account: any }, hre) => {
//     const account = await hre.ethers.getSigners();
//     const amount = hre.ethers.utils.parseUnits(taskArgs.amount, 18);

//     const signer = new Wallet(privateKey);

//     let signature = await signer.signMessage(
//       ethers.utils
//         .solidityKeccak256(
//           ["address", "uint256"],
//           ["0xb5dF6F49291573d8FF3b06E3d8e25B95EDB419EE", 2]
//         )
//         .slice(2)
//     );

//     console.log(signature);
//   });

// export default;

// task(
//   "hello",
//   "Prints 'Hello, World!'",
//   async function (taskArguments, hre, runSuper) {
//     console.log("Hello, World!");
//   }
// );
