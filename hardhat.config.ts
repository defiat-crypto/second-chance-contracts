import "dotenv/config";
import { HardhatUserConfig } from "hardhat/config";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "hardhat-abi-exporter";
import "hardhat-spdx-license-identifier";
import "hardhat-typechain";

const config: HardhatUserConfig = {
  solidity: "0.6.6",
  paths: {
    artifacts: "./build/artifacts",
    cache: "./build/cache",
  },
  abiExporter: {
    path: "./build/abi",
    clear: true,
    flat: true,
  },
  spdxLicenseIdentifier: {
    overwrite: true,
    runOnCompile: true,
  },
  namedAccounts: {
    mastermind: 0,
    deployer: "0x0419eB10E9c1efFb47Cb6b5B1B2B2B3556395ae1",
    token: {
      1: "0xB6eE603933E024d8d53dDE3faa0bf98fE2a3d6f1",
      4: "0xB571d40e4A7087C1B73ce6a3f29EaDfCA022C5B2",
      31337: "0x0165878A594ca255338adfa4d48449f69242Eb8F",
    },
    points: {
      1: "0xeB23dF02AB127aF9249227441BC4Df4d5230f02A",
      4: "0x70c7d7856e1558210cfbf27b7f17853655752453",
      31337: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
    },
    gov: {
      1: "0x3Aa3303877A0D1c360a9FE2693AE9f31087A1381",
      4: "0x064fd7d9c228e8a4a2bf247b432a34d6e1cb9442",
      31337: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
    },
  },
  external: {
    contracts: [
      {
        artifacts: "node_modules/@defiat-crypto/core-contracts/build/artifacts",
        deploy: "node_modules/@defiat-crypto/core-contracts/build/deploy",
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        blockNumber: 11705000,
        url: process.env.ALCHEMY_MAIN_DEV_KEY || "",
      },
    },
    localhost: {
      url: "http://localhost:8545",
    },
  },
};

export default config;
