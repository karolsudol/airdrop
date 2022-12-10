import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Token } from "../typechain-types";

import { expect } from "chai";
import { ethers } from "hardhat";

describe("TokenEMB - ownable", () => {
  let owner: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let rest: SignerWithAddress[];
  let SYMBOL: string;
  let NAME: string;

  let ZERO_ADDRESS: string;
  let token: Token;

  beforeEach(async function () {
    [owner, account1, account2, ...rest] = await ethers.getSigners();
    NAME = "TokenEMB";
    SYMBOL = "EMB";
    ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

    token = (await (
      await ethers.getContractFactory(NAME)
    ).deploy(NAME, SYMBOL)) as Token;
    await token.deployed();
  });

  describe("deploy", async function () {
    it("should set name correctly", async () => {
      expect(await token.name()).to.equal(NAME);
    });
    it("should set symbol correctly", async () => {
      expect(await token.symbol()).to.equal(SYMBOL);
    });
    it("should set supply correctly", async () => {
      expect(await token.totalSupply()).to.equal(0);
    });
  });
  describe("minting", async function () {
    it("should mint correctly", async () => {
      await expect(token.connect(owner).mint(account1.address, 100))
        .to.emit(token, "Transfer")
        .withArgs(ZERO_ADDRESS, account1.address, 100);

      expect(await token.totalSupply()).to.equal(100);
      expect(await token.balanceOf(account1.address)).to.equal(100);
    });

    it("should revert minting for zero address correctly", async () => {
      await expect(token.mint(ZERO_ADDRESS, 100)).to.be.revertedWith(
        "ERC20: mint to the zero address"
      );
    });
    it("should revert minting for non minter role address correctly", async () => {
      await expect(
        token.connect(account1).mint(ZERO_ADDRESS, 100)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("transfer ownership to mint", async function () {
    it("should transfer owner correctly", async () => {
      await token.connect(owner).transferOwnership(account1.address);
      await expect(token.connect(account1).mint(account2.address, 100))
        .to.emit(token, "Transfer")
        .withArgs(ZERO_ADDRESS, account2.address, 100);
    });
    it("should revert transfering owner for non owner correctly", async () => {
      await expect(token.connect(account1).transferOwnership(account1.address))
        .to.be.reverted;
    });
  });
});
