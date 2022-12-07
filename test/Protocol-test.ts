import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { formatEther, parseEther, parseUnits } from "ethers/lib/utils";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Protocol, EMBToken, ERC20 } from "../typechain-types";

import { expect } from "chai";
import { ethers } from "hardhat";

describe("Protocol", () => {
  const provider = ethers.provider;
  let owner: SignerWithAddress;
  let signer: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let rest: SignerWithAddress[];

  let EMBToken: EMBToken;
  let protocol: Protocol;
  let merkleRoot: string;

  let SYMBOL: string;
  let NAME: string;
  let roleMinter: string;

  beforeEach(async function () {
    [owner, signer, account1, account2, ...rest] = await ethers.getSigners();

    NAME = "EMBToken";
    SYMBOL = "EMB";

    roleMinter = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("MINTER_ROLE")
    );

    EMBToken = (await (
      await ethers.getContractFactory(NAME)
    ).deploy(NAME, SYMBOL)) as EMBToken;
    await EMBToken.deployed();
  });

  beforeEach(async function () {
    protocol = await (
      await ethers.getContractFactory("Protocol")
    ).deploy(signer.address, EMBToken.address);
    await protocol.deployed();
  });

  describe("setup", async function () {
    it("should deploy correctly", async () => {});
  });
  describe("Signature minting", async function () {
    it("TODO", async () => {});
  });
});
