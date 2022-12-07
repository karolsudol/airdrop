import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { formatEther, parseEther, parseUnits } from "ethers/lib/utils";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Protocol, EMBToken, ERC20 } from "../typechain-types";

import { expect } from "chai";
import { ethers } from "hardhat";

describe("Protocol", () => {
  const provider = ethers.provider;
  let owner: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let rest: SignerWithAddress[];

  let EMBToken: EMBToken;
  let protocol: Protocol;
  let merkleRoot: string;
  beforeEach(async function () {
    [owner, account1, account2, ...rest] = await ethers.getSigners();

    EMBToken = (await (
      await ethers.getContractFactory("EMBToken")
    ).deploy("EMB Token", "EMB")) as EMBToken;
    await EMBToken.deployed();
  });

  beforeEach(async function () {
    protocol = await (
      await ethers.getContractFactory("Protocol")
    ).deploy(account1.address, EMBToken.address);
    await protocol.deployed();
  });

  describe("setup", async function () {
    it("should deploy correctly", async () => {});
  });
  describe("Signature minting", async function () {
    it("TODO", async () => {});
  });
});
