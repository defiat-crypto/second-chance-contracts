import { network } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { SecondChance } from "../typechain";

const func: DeployFunction = async ({
  ethers,
  deployments,
  getNamedAccounts,
}) => {
  const { deploy } = deployments;
  const { mastermind, token } = await getNamedAccounts();

  const result = await deploy("SecondChance", {
    from: mastermind,
    log: true,
  });

  if (result.newlyDeployed) {
    // do any initial setup

    if (!network.live) {
      const Second = (await ethers.getContract(
        "SecondChance",
        mastermind
      )) as SecondChance;

      await Second.setDFT(token).then((tx) => tx.wait());
    }
  }
};

export default func;
