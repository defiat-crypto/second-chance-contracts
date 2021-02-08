import { ethers, deployments, getNamedAccounts } from "hardhat";
import { expect } from "chai";
import { SecondChance, RugSanctuary } from "../typechain";

describe("RugSanctuary", () => {
  beforeEach(async () => {
    await deployments.fixture();
  });

  it("Should deploy the staking pool", async () => {
    const { mastermind, deployer } = await getNamedAccounts();
    const SecondChance = (await ethers.getContract(
      "SecondChance",
      mastermind
    )) as SecondChance;
    const Sanctuary = (await ethers.getContract(
      "RugSanctuary",
      mastermind
    )) as RugSanctuary;

    const second = await Sanctuary.second();
    const treasury = await Sanctuary.Treasury();
    const fee = await Sanctuary.treasuryFee();
    const lockRatio = await Sanctuary.lockRatio100();

    expect(second).eq(SecondChance.address);
    expect(treasury).eq(deployer);
    expect(fee.toNumber()).eq(100);
    expect(lockRatio.toNumber()).eq(90);
  });
});
