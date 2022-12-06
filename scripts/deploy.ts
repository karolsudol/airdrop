import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { Protocol, ERC20, EMBToken } from "../typechain-types";

const provider = ethers.provider
let account1: SignerWithAddress
let account2: SignerWithAddress
let rest: SignerWithAddress[]

let EMBToken: EMBToken
let protocol: Protocol
let merkleRoot: string

describe("Protocol", function () {
  before(async () => {
    ;[account1, account2, ...rest] = await ethers.getSigners()

    EMBToken = (await (await ethers.getContractFactory("EMBToken")).deploy("EMB Token", "EMB")) as EMBToken
    await EMBToken.deployed()
  })

  beforeEach(async () => {
    protocol = await (await ethers.getContractFactory("Protocol")).deploy(account1.address, EMBToken.address)
    await protocol.deployed()
  })

  describe("setup", () => {

    it("should deploy correctly", async () => {
      // if the beforeEach succeeded, then this succeeds
    })

  describe("Signature minting", () => {
    it ("TODO", async () => {
      throw new Error("TODO: add more tests here!")
    })
  })
});