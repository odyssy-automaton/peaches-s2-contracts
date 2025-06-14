import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFn: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, network } = hre;
  const { deployer } = await hre.getNamedAccounts();

  console.log("deployer", deployer);

  console.log("\nDeploying PeachTycoonTreeSeason3 on network:", network.name);

  const shamanDeployed = await deployments.deploy("PeachTycoonTreeSeason3", {
    contract: "PeachTycoonTreeSeason3",
    from: deployer,
    args: [],
    // proxy: {
    //     proxyContract: 'UUPS',
    //     methodName: 'initialize',
    // },
    log: true,
  });
  console.log("PeachTycoonTreeSeason3 deployment Tx ->", shamanDeployed.transactionHash);
};

export default deployFn;
deployFn.id = "001_deploy_Nfts_PeachTycoonTreeSeason3"; // id required to prevent reexecution
deployFn.tags = ["PeachTycoonTreeSeason3"];
