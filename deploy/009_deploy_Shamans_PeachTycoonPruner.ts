import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFn: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, network } = hre;
  const { deployer } = await hre.getNamedAccounts();

  console.log("\nDeploying mock PeachTycoonPruner on network:", network.name);

  const shamanDeployed = await deployments.deploy("PeachTycoonPruner", {
    contract: "PeachTycoonPruner",
    from: deployer,
    args: [],
    // proxy: {
    //     proxyContract: 'UUPS',
    //     methodName: 'initialize',
    // },
    log: true,
  });
  console.log("PeachTycoonPruner deployment Tx ->", shamanDeployed.transactionHash);
};

export default deployFn;
deployFn.id = "009_deploy_Mocks_PeachTycoonPruner"; // id required to prevent reexecution
deployFn.tags = ["ShamanPeachTycoonPruner"];
