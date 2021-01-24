import { BigNumber } from 'ethers';
import { parseEther } from 'ethers/lib/utils';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async ({getNamedAccounts, deployments}) => {  
  const {execute} = deployments;
  const {deployer} = await getNamedAccounts();
  const farm = await deployments.get('RugSanctuary');

  // await execute(
  //   'SecondChance', 
  //   {
  //     from: deployer,
  //     log: true
  //   },
  //   'setDFT',
  //   '0xB6eE603933E024d8d53dDE3faa0bf98fE2a3d6f1'
  // );
  
  await execute(
    'SecondChance', 
    {
      from: deployer,
      log: true,
      value: parseEther('50')
    },
    'initialSetup',
    farm.address
  );
};

export default func;