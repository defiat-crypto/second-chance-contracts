import { ethers, deployments, getNamedAccounts } from "hardhat";
import { expect } from "chai";
import { SecondChance, RugSanctuary } from "../typechain";

describe("RugSanctuary", () => {
  beforeEach(async () => {
    await deployments.fixture();
  });

  it("Should deploy the staking pool", async () => {
    const { deployer } = await getNamedAccounts();
    const SecondChance = (await ethers.getContract(
      "SecondChance",
      deployer
    )) as SecondChance;
    const Sanctuary = (await ethers.getContract(
      "RugSanctuary",
      deployer
    )) as RugSanctuary;

    const second = await Sanctuary.second();
    const treausury = await Sanctuary.Treasury();
    const fee = await Sanctuary.treasuryFee();
    const lockRatio = await Sanctuary.lockRatio100();

    expect(second).eq(SecondChance.address);
    expect(treausury).eq("0x0419eB10E9c1efFb47Cb6b5B1B2B2B3556395ae1");
    expect(fee.toNumber()).eq(100);
    expect(lockRatio.toNumber()).eq(90);
  });
});
