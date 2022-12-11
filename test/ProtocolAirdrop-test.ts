import { Wallet } from "ethers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ProtocolAirdrop, TokenEMB } from "../typechain-types";
import { expect } from "chai";
import { ethers } from "hardhat";

function hashToken(account: string, amount: string) {
  return Buffer.from(
    ethers.utils
      .solidityKeccak256(["address", "uint256"], [account, amount])
      .slice(2),
    "hex"
  );
}

describe("Protocol Airdrop", () => {
  const provider = ethers.provider;

  let owner: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let account3: SignerWithAddress;
  // let rest: SignerWithAddress[];

  let token: TokenEMB;
  let airdrop: ProtocolAirdrop;
  // let merkleRoot: string;

  const MAX_SUPPLY = 4;
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
    [owner, account1, account2, account3] = await ethers.getSigners();

    allowlistedAddresses = [account1.address, account2.address];

    walletAddress = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266";

    privateKey =
      "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

    signer = new Wallet(privateKey);

    token = (await (
      await ethers.getContractFactory(NAME)
    ).deploy(NAME, SYMBOL)) as TokenEMB;
    await token.deployed();

    airdrop = (await (
      await ethers.getContractFactory("ProtocolAirdrop")
    ).deploy(
      signer.address,
      token.address,
      MAX_SUPPLY,
      MAX_PER_MINT
    )) as ProtocolAirdrop;
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

  describe("auth with PersonalSign", async function () {
    describe("minting with signature", async function () {
      describe("mint as expected", async function () {
        it("should mint correctly", async () => {
          expect(await token.balanceOf(account1.address)).to.equal(0);
          expect(await token.totalSupply()).to.equal(0);

          await token.connect(owner).transferOwnership(airdrop.address);

          signature = await signer.signMessage(
            hashToken(account1.address, "2")
          );

          await expect(
            airdrop
              .connect(account1)
              .claimAirdrop(account1.address, 2, signature)
          )
            .to.emit(airdrop, "AirdropProcessed")
            .withArgs(account1.address, 2);

          expect(await token.totalSupply()).to.equal(2);
          expect(await token.balanceOf(account1.address)).to.equal(2);
        });
      });

      describe("mint - prevent hacks", async function () {
        it("should revert mint when protocol is not token owner", async () => {
          signature = await signer.signMessage(
            hashToken(account1.address, "2")
          );

          await expect(
            airdrop
              .connect(account1)
              .claimAirdrop(account1.address, 2, signature)
          ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("should revert mint when invalid signature", async () => {
          await token.connect(owner).transferOwnership(airdrop.address);

          signature = await signer.signMessage(
            hashToken(account3.address, "2")
          );

          await expect(
            airdrop
              .connect(account1)
              .claimAirdrop(account1.address, 2, signature)
          ).to.be.revertedWith("Airdrop: Invalid signature");
        });

        it("should revert mint when minter used signature", async () => {
          await token.connect(owner).transferOwnership(airdrop.address);

          signature = await signer.signMessage(
            hashToken(account1.address, "2")
          );

          await airdrop
            .connect(account1)
            .claimAirdrop(account1.address, 2, signature);

          await expect(
            airdrop
              .connect(account1)
              .claimAirdrop(account1.address, 2, signature)
          ).to.be.revertedWith("Airdrop: Signature has already been used");
        });

        it("should revert when all allocation is used", async () => {
          await token.connect(owner).transferOwnership(airdrop.address);

          await airdrop
            .connect(account1)
            .claimAirdrop(
              account1.address,
              2,
              signer.signMessage(hashToken(account1.address, "2"))
            );

          await airdrop
            .connect(account2)
            .claimAirdrop(
              account2.address,
              2,
              signer.signMessage(hashToken(account2.address, "2"))
            );

          await expect(
            airdrop
              .connect(account3)
              .claimAirdrop(
                account3.address,
                2,
                signer.signMessage(hashToken(account3.address, "2"))
              )
          ).to.be.revertedWith("Airdrop: maxed supply");
        });

        it("should revert when minter used its allocation", async () => {
          await token.connect(owner).transferOwnership(airdrop.address);

          signature = await signer.signMessage(
            hashToken(account1.address, "3")
          );

          await expect(
            airdrop
              .connect(account1)
              .claimAirdrop(account1.address, 3, signature)
          ).to.be.revertedWith("Airdrop: exceeded token amount per mint");
        });
      });
    });
  });

  // describe("auth with PersonalSign", async function () {
  //   describe("mint", async function () {
  //     it("should mint correctly", async () => {});

  //     it("should revert mint correctly when contract has no rights to mint", async () => {});
  //   });
  //   describe("duplicate mint", async function () {
  //     it("should mint correctly", async () => {});

  //     it("should revert mint correctly when contract has no rights to mint", async () => {});
  //   });
  //   describe("frontrun", async function () {
  //     it("should mint correctly", async () => {});

  //     it("should revert mint correctly when contract has no rights to mint", async () => {});
  //   });
  // });
});
