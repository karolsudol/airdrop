import { Wallet } from "ethers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ProtocolAirdrop, TokenEMB } from "../typechain-types";
import { expect } from "chai";
import { ethers } from "hardhat";
import { utils } from "../typechain-types/@openzeppelin/contracts";

// import {} from "../contracts/ver"
// import { MerkleTree } from "merkletreejs";

function hash(account: string, amount: string) {
  return Buffer.from(
    ethers.utils
      .solidityKeccak256(["address", "uint256"], [account, amount])
      .slice(2),
    "hex"
  );
}

describe("Protocol Airdrop", () => {
  const provider = ethers.provider;
  // let merkleTree: MerkleTree;

  let owner: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let account3: SignerWithAddress;

  let token: TokenEMB;
  let airdrop: ProtocolAirdrop;
  let merkleRoot: string;

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
    // merkleTree = new MerkleTree(
    //   Object.entries().map((token) => hash(...token)),
    //   keccak256,
    //   { sortPairs: true }
    // );

    // const ReentrancyMock = artifacts.require("ReentrancyMock");
    // const ReentrancyAttack = artifacts.require("ReentrancyAttack");

    [owner, account1, account2, account3] = await ethers.getSigners();

    allowlistedAddresses = [account1.address, account2.address];

    walletAddress = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266";

    privateKey =
      "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

    signer = new Wallet(privateKey);

    const Lib = await ethers.getContractFactory("ProtocolEIP712");
    const lib = await Lib.deploy();
    await lib.deployed();

    token = (await (
      await ethers.getContractFactory(NAME)
    ).deploy(NAME, SYMBOL)) as TokenEMB;
    await token.deployed();

    airdrop = (await (
      await ethers.getContractFactory("ProtocolAirdrop", {
        libraries: {
          ProtocolEIP712: lib.address,
        },
      })
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

  describe("auth with message", async function () {
    describe("minting with signature", async function () {
      it("should mint correctly", async () => {
        expect(await token.balanceOf(account1.address)).to.equal(0);
        expect(await token.totalSupply()).to.equal(0);

        await token.connect(owner).transferOwnership(airdrop.address);

        signature = await signer.signMessage(hash(account1.address, "2"));

        await expect(
          airdrop.connect(account1).claimAirdrop(account1.address, 2, signature)
        )
          .to.emit(airdrop, "AirdropProcessed")
          .withArgs(account1.address, 2);

        expect(await token.totalSupply()).to.equal(2);
        expect(await token.balanceOf(account1.address)).to.equal(2);
      });

      it("should revert mint when protocol is not token owner", async () => {
        signature = await signer.signMessage(hash(account1.address, "2"));

        await expect(
          airdrop.connect(account1).claimAirdrop(account1.address, 2, signature)
        ).to.be.revertedWith("Ownable: caller is not the owner");
      });

      it("should revert mint when invalid signature", async () => {
        await token.connect(owner).transferOwnership(airdrop.address);

        signature = await signer.signMessage(hash(account3.address, "2"));

        await expect(
          airdrop.connect(account1).claimAirdrop(account1.address, 2, signature)
        ).to.be.revertedWith("EIP712: unauthorized signer");
      });

      it("should revert mint when minter used signature", async () => {
        await token.connect(owner).transferOwnership(airdrop.address);

        signature = await signer.signMessage(hash(account1.address, "2"));

        await airdrop
          .connect(account1)
          .claimAirdrop(account1.address, 2, signature);

        await expect(
          airdrop.connect(account1).claimAirdrop(account1.address, 2, signature)
        ).to.be.revertedWith("Airdrop: Signature has already been used");
      });

      it("should revert when all allocation is used", async () => {
        await token.connect(owner).transferOwnership(airdrop.address);

        await airdrop
          .connect(account1)
          .claimAirdrop(
            account1.address,
            2,
            signer.signMessage(hash(account1.address, "2"))
          );

        await airdrop
          .connect(account2)
          .claimAirdrop(
            account2.address,
            2,
            signer.signMessage(hash(account2.address, "2"))
          );

        await expect(
          airdrop
            .connect(account3)
            .claimAirdrop(
              account3.address,
              2,
              signer.signMessage(hash(account3.address, "2"))
            )
        ).to.be.revertedWith("Airdrop: maxed supply");
      });

      it("should revert when minter used its allocation", async () => {
        await token.connect(owner).transferOwnership(airdrop.address);

        signature = await signer.signMessage(hash(account1.address, "3"));

        await expect(
          airdrop.connect(account1).claimAirdrop(account1.address, 3, signature)
        ).to.be.revertedWith("Airdrop: exceeded token amount per mint");
      });
    });
  });

  describe("auth with signed typed ERC721", async function () {
    it("should mint correctly", async () => {
      await token.connect(owner).transferOwnership(airdrop.address);

      const minter = account1.address;
      const amount = 2;

      /**
       * signer creates signature
       */
      const signature = await signer._signTypedData(
        // Domain
        {
          name: "Airdrop",
          version: "1",
          chainId: 51,
          verifyingContract: airdrop.address,
        },
        // Types
        {
          Mint: [
            { name: "minter", type: "address" },
            { name: "amount", type: "uint256" },
          ],
        },
        // Value
        { minter, amount }
      );

      await airdrop.connect(account1).claimAirdrop(minter, amount, signature);
    });

    it("should revert mint with invalid signature correctly", async () => {
      await token.connect(owner).transferOwnership(airdrop.address);

      const minter = account1.address;
      const amount = 2;

      /**
       * signer creates signature
       */
      const signature = await signer._signTypedData(
        // Domain
        {
          name: "XXXXXXXXX",
          version: "1",
          chainId: 51,
          verifyingContract: airdrop.address,
        },
        // Types
        {
          Mint: [
            { name: "minter", type: "address" },
            { name: "amount", type: "uint256" },
          ],
        },
        // Value
        { minter, amount }
      );

      await expect(
        airdrop.connect(account1).claimAirdrop(minter, amount, signature)
      ).to.be.revertedWith("EIP712: unauthorized signer");
    });

    it("should revert mint with wrong signature lenghth correctly", async () => {
      await token.connect(owner).transferOwnership(airdrop.address);

      const minter = account1.address;
      const amount = 2;

      await expect(
        airdrop
          .connect(account1)
          .claimAirdrop(
            minter,
            amount,
            "0x45544800000000000000000000000000000000000000000000000000000000"
          )
      ).to.be.revertedWith("Airdrop: invalid signature length");
    });

    it("should revert mint when signed with zero address correctly", async () => {});
  });

  // describe("auth with merkle tree root", async function () {
  //   it("should mint correctly", async () => {
  //     // await token.connect(owner).transferOwnership(airdrop.address);
  //     // await airdrop.connect(account1).claimAirdrop(minter, amount, signature);
  //   });
  // });
});
