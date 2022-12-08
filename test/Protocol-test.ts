import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { formatEther, parseEther, parseUnits } from "ethers/lib/utils";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Protocol, EMBToken, ERC20, IERC20 } from "../typechain-types";

import { expect } from "chai";
import { ethers } from "hardhat";
import { types } from "hardhat/config";

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

  describe("deploy", async function () {
    // it("should set signer correctly", async () => {
    //   expect(await protocol.signer.getAddress()).to.equal(signer.address);
    // });
    // it("should set EMBToken correctly", async () => {
    //   expect(types(protocol.EMBToken)).to.equal(EMBToken.address);
    // });
  });
  describe("Signature minting", async function () {
    it("TODO", async () => {});
  });
});
