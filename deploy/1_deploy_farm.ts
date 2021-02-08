import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { mastermind } = await getNamedAccounts();
  const second = await deployments.get("SecondChance");

  const result = await deploy("RugSanctuary", {
    from: mastermind,
    log: true,
    args: [second.address],
  });

  if (result.newlyDeployed) {
    // do any initial setup
  }
};

export default func;
