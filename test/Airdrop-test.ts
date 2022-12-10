import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { formatEther, parseEther, parseUnits } from "ethers/lib/utils";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Airdrop, Token, ERC20, IERC20 } from "../typechain-types";

import { expect } from "chai";
import { ethers } from "hardhat";
import { types } from "hardhat/config";

describe("Airdrop", () => {
  const provider = ethers.provider;

  let owner: SignerWithAddress;
  let signer: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  // let rest: SignerWithAddress[];

  let token: Token;
  let airdrop: Airdrop;
  // let merkleRoot: string;

  const MAX_SUPPLY = 10;
  const MAX_PER_MINT = 2;

  const NAME = "Token";
  const SYMBOL = "TKN";

  beforeEach(async function () {
    [owner, account1, account2] = await ethers.getSigners();

    token = (await (
      await ethers.getContractFactory(NAME)
    ).deploy(NAME, SYMBOL)) as Token;
    await token.deployed();
  });

  beforeEach(async function () {
    airdrop = (await (
      await ethers.getContractFactory("Airdrop")
    ).deploy(
      owner.address,
      token.address,
      MAX_SUPPLY,
      MAX_PER_MINT
    )) as Airdrop;
    await airdrop.deployed();
  });

  describe("deploy", async function () {
    it("should set signer correctly", async () => {
      // expect(await airdrop.signer.getAddress()).to.equal(
      //   await signer.getAddress()
      // );
    });
    it("should set token correctly", async () => {
      // expect(airdrop.token).to.equal(token.address);
    });
  });
  describe("signature minting", async function () {
    it("should mint correctly", async () => {
      expect(await token.balanceOf(account1.address)).to.equal(0);
      expect(await token.totalSupply()).to.equal(0);

      await token.connect(owner).transferOwnership(airdrop.address);

      let messageHash = ethers.utils.solidityKeccak256(
        ["address", "uint256"],
        [account1.address, 2]
      );
      const messageArray = ethers.utils.arrayify(messageHash);
      const rawSignature = await owner.signMessage(messageArray);
      // console.log("signer          ", signer.address);
      // console.log(
      //   "signer airdrop          ",
      //   await airdrop.signer.getAddress()
      // );
      // console.log(" airdrop          ", airdrop.address);
      // console.log("token airdrop          ", await token.signer.getAddress());

      await airdrop.connect(account1).signatureMint(rawSignature, 2);
    });
  });
});
