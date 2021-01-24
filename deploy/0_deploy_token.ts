import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async ({getNamedAccounts, deployments}) => {  
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();
  
  const result = await deploy('SecondChance', {
    from: deployer,
    log: true
  })

  if (result.newlyDeployed) {
    // do any initial setup
  }
};

export default func;