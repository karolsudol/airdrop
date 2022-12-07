import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { formatEther, parseEther, parseUnits } from "ethers/lib/utils";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Protocol, EMBToken, ERC20 } from "../typechain-types";

import { expect } from "chai";
import { ethers } from "hardhat";
import { string } from "hardhat/internal/core/params/argumentTypes";

describe("EMB-Token", () => {
  const provider = ethers.provider;
  let owner: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let rest: SignerWithAddress[];
  let SYMBOL: string;
  let NAME: string;
  let roleMinter: string;
  let ZERO_ADDRESS: string;

  let EMBToken: EMBToken;
  beforeEach(async function () {
    [owner, account1, account2, ...rest] = await ethers.getSigners();
    NAME = "EMBToken";
    SYMBOL = "EMB";
    ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

    roleMinter = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("MINTER_ROLE")
    );

    EMBToken = (await (
      await ethers.getContractFactory(NAME)
    ).deploy(NAME, SYMBOL)) as EMBToken;
    await EMBToken.deployed();
  });

  describe("deploy", async function () {
    it("should set name correctly", async () => {
      expect(await EMBToken.name()).to.equal(NAME);
    });
    it("should set symbol correctly", async () => {
      expect(await EMBToken.symbol()).to.equal(SYMBOL);
    });
    it("should set supply correctly", async () => {
      expect(await EMBToken.totalSupply()).to.equal(0);
    });
  });
  describe("minting", async function () {
    it("should mint correctly", async () => {
      await expect(EMBToken.connect(owner).mint(account1.address, 100))
        .to.emit(EMBToken, "Transfer")
        .withArgs(ZERO_ADDRESS, account1.address, 100);

      expect(await EMBToken.totalSupply()).to.equal(100);
      expect(await EMBToken.balanceOf(account1.address)).to.equal(100);
    });

    it("should revert minting for zero address correctly", async () => {
      await expect(EMBToken.mint(ZERO_ADDRESS, 100)).to.be.revertedWith(
        "ERC20: mint to the zero address"
      );
    });
    it("should revert minting for non minter role address correctly", async () => {
      await expect(
        EMBToken.connect(account1).mint(ZERO_ADDRESS, 100)
      ).to.be.revertedWith("Caller is not a minter");
    });
  });

  describe("grant roles", async function () {
    it("should grant mint role correctly", async () => {
      await EMBToken.connect(owner).grantRole(roleMinter, account1.address);
      await expect(EMBToken.connect(account1).mint(account2.address, 100))
        .to.emit(EMBToken, "Transfer")
        .withArgs(ZERO_ADDRESS, account2.address, 100);
    });

    it("should revert granting mint role for non admin correctly", async () => {
      await expect(
        EMBToken.connect(account1).grantRole(roleMinter, account1.address)
      ).to.be.reverted;
    });
  });
});
