import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

import "./tasks/bridge-tasks";
import * as dotenv from "dotenv";
dotenv.config();

const SEPOLIA_URL = `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`;
const GOERLI_URL = `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`;
const BSC_TEST_URL = `https://data-seed-prebsc-1-s1.binance.org:8545/}`;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    sepolia: {
      url: SEPOLIA_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    goerli: {
      url: GOERLI_URL || "",
      allowUnlimitedContractSize: true,
      // blockGasLimit: 100000000429720,

      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    bsctestnet: {
      url: BSC_TEST_URL || "",
      allowUnlimitedContractSize: true,
      chainId: 97,
      gasPrice: 20000000000,

      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
    // apiKey: process.env.BSCSCAN_API_KEY,
  },
};

export default config;
