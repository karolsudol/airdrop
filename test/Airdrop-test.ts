import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { formatEther, parseEther, parseUnits } from "ethers/lib/utils";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Airdrop, Token, ERC20, IERC20 } from "../typechain-types";

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

  let token: Token;
  let airdrop: Airdrop;
  let merkleRoot: string;

  const MAX_SUPPLY = 10;
  const MAX_PER_MINT = 2;

  const NAME = "Token";
  const SYMBOL = "TKN";

  beforeEach(async function () {
    [owner, signer, account1, account2, ...rest] = await ethers.getSigners();

    token = (await (
      await ethers.getContractFactory(NAME)
    ).deploy(NAME, SYMBOL)) as Token;
    await token.deployed();
  });

  beforeEach(async function () {
    airdrop = (await (
      await ethers.getContractFactory("Airdrop")
    ).deploy(
      signer.address,
      token.address,
      MAX_SUPPLY,
      MAX_PER_MINT
    )) as Airdrop;
    await airdrop.deployed();
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
