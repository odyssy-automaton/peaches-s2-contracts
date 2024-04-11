import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFn: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, network } = hre;
  const { deployer } = await hre.getNamedAccounts();

  console.log("\nDeploying mock PeachTycoonFertilzer on network:", network.name);

  const shamanDeployed = await deployments.deploy("PeachTycoonFertilzer", {
    contract: "PeachTycoonFertilzer",
    from: deployer,
    args: [],
    // proxy: {
    //     proxyContract: 'UUPS',
    //     methodName: 'initialize',
    // },
    log: true,
  });
  console.log("PeachTycoonFertilzer deployment Tx ->", shamanDeployed.transactionHash);
};

export default deployFn;
deployFn.id = "009_deploy_Mocks_PeachTycoonFertilzer"; // id required to prevent reexecution
deployFn.tags = ["ShamanPeachTycoonFertilzer"];
