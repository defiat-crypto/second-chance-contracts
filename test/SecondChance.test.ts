import { ethers, deployments, getNamedAccounts } from "hardhat";
import { expect } from "chai";
import { SecondChance, RugSanctuary } from "../typechain";

describe("SecondChanceToken", () => {
  beforeEach(async () => {
    await deployments.fixture();
  });

  it("Should deploy the Token", async () => {
    const { deployer } = await getNamedAccounts();
    const SecondChance = (await ethers.getContract(
      "SecondChance",
      deployer
    )) as SecondChance;
    const Farm = (await ethers.getContract(
      "RugSanctuary",
      deployer
    )) as RugSanctuary;

    const name = await SecondChance.name();
    const symbol = await SecondChance.symbol();
    const dft = await SecondChance.DFT();
    const farm = await SecondChance.farm();
    const balance = await SecondChance.balanceOf(deployer);

    expect(name).eq("2nd_Chance");
    expect(symbol).eq("2ND");
    expect(dft).eq("0xB6eE603933E024d8d53dDE3faa0bf98fE2a3d6f1");
    expect(farm).eq(Farm.address);
    expect(balance.eq(ethers.utils.parseEther("10000"))).true;
  });
});
