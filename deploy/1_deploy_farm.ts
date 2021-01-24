import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async ({getNamedAccounts, deployments}) => {  
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();
  const second = await deployments.get('SecondChance');
  
  const result = await deploy('RugSanctuary', {
    from: deployer,
    log: true,
    args: [second.address]
  })

  if (result.newlyDeployed) {
    // do any initial setup
  }
};

export default func;