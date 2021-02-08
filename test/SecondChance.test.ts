import { ethers, deployments, getNamedAccounts } from "hardhat";
import { expect } from "chai";
import { SecondChance, RugSanctuary } from "../typechain";

describe("SecondChanceToken", () => {
  beforeEach(async () => {
    await deployments.fixture();
  });

  it("Should deploy the Token", async () => {
    const { mastermind, token } = await getNamedAccounts();
    const SecondChance = (await ethers.getContract(
      "SecondChance",
      mastermind
    )) as SecondChance;
    const Farm = (await ethers.getContract(
      "RugSanctuary",
      mastermind
    )) as RugSanctuary;

    const name = await SecondChance.name();
    const symbol = await SecondChance.symbol();
    const dft = await SecondChance.DFT();
    const farm = await SecondChance.farm();
    const balance = await SecondChance.balanceOf(mastermind);

    expect(name).eq("2nd_Chance");
    expect(symbol).eq("2ND");
    expect(dft).eq(token);
    expect(farm).eq(Farm.address);
    expect(balance.eq(ethers.utils.parseEther("10000"))).true;
  });
});
