import { Wallet } from "ethers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Protocol, Token, ERC20, IERC20 } from "../typechain-types";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("ProtocolPersonalSign-Airdrop", () => {
  const provider = ethers.provider;

  let owner: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  // let rest: SignerWithAddress[];

  let token: Token;
  let airdrop: Protocol;
  // let merkleRoot: string;

  const MAX_SUPPLY = 10;
  const MAX_PER_MINT = 2;

  const NAME = "TokenEMB";
  const SYMBOL = "EMB";

  // Define a list of allowlisted wallets
  let allowlistedAddresses: string[];

  // Define wallet that will be used to sign messages
  let walletAddress: string; // owner.address
  let privateKey: string;
  let signer: Wallet;

  let messageHash, signature;

  beforeEach(async function () {
    [owner, account1, account2] = await ethers.getSigners();

    allowlistedAddresses = [account1.address, account2.address];

    walletAddress = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266";

    privateKey =
      "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

    signer = new Wallet(privateKey);

    token = (await (
      await ethers.getContractFactory(NAME)
    ).deploy(NAME, SYMBOL)) as Token;
    await token.deployed();

    airdrop = (await (
      await ethers.getContractFactory("ProtocolPersonalSign")
    ).deploy(
      signer.address,
      token.address,
      MAX_SUPPLY,
      MAX_PER_MINT
    )) as Protocol;
    await airdrop.deployed();
  });

  describe("deploy", async function () {
    it("should set signer correctly", async () => {
      expect(await airdrop.signer.getAddress()).to.equal(
        await signer.getAddress()
      );
    });
    it("should set token correctly", async () => {
      expect(await airdrop.token()).to.equal(token.address);
    });
  });
  describe("airdrop minting with signature", async function () {
    it("should mint correctly for approved address", async () => {
      expect(await token.balanceOf(account1.address)).to.equal(0);
      expect(await token.totalSupply()).to.equal(0);

      await token.connect(owner).transferOwnership(airdrop.address);

      messageHash = ethers.utils.id(allowlistedAddresses[0]);

      let messageBytes = ethers.utils.arrayify(messageHash);
      signature = await signer.signMessage(messageBytes);

      const recover = await airdrop.recoverSigner(messageHash, signature);

      await airdrop
        .connect(account1)
        .claimAirdrop(account1.address, 2, messageHash, signature);

      expect(await token.totalSupply()).to.equal(2);
      expect(await token.balanceOf(account1.address)).to.equal(2);
    });

    it("should revert mint correctly for  address", async () => {});
  });
});
