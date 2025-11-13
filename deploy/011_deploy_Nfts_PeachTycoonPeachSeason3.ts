import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFn: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, network } = hre;
  const { deployer } = await hre.getNamedAccounts();

  console.log("deployer", deployer);

  console.log("\nDeploying PeachTycoonPeachSeason3 on network:", network.name);

  const shamanDeployed = await deployments.deploy("PeachTycoonPeachSeason3", {
    contract: "PeachTycoonPeachSeason3",
    from: deployer,
    args: [],
    // proxy: {
    //     proxyContract: 'UUPS',
    //     methodName: 'initialize',
    // },
    log: true,
  });
  console.log("PeachTycoonPeachSeason3 deployment Tx ->", shamanDeployed.transactionHash);
};

export default deployFn;
deployFn.id = "001_deploy_Nfts_PeachTycoonPeachSeason3"; // id required to prevent reexecution
deployFn.tags = ["NftsPeachTycoonPeachSeason3"];
