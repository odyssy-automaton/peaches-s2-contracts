import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFn: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, network } = hre;
  const { deployer } = await hre.getNamedAccounts();

  console.log("\nDeploying mock PeachTycoonSprayer on network:", network.name);

  const shamanDeployed = await deployments.deploy("PeachTycoonSprayer", {
    contract: "PeachTycoonSprayer",
    from: deployer,
    args: [],
    // proxy: {
    //     proxyContract: 'UUPS',
    //     methodName: 'initialize',
    // },
    log: true,
  });
  console.log("PeachTycoonSprayer deployment Tx ->", shamanDeployed.transactionHash);
};

export default deployFn;
deployFn.id = "009_deploy_Mocks_PeachTycoonSprayer"; // id required to prevent reexecution
deployFn.tags = ["ShamanPeachTycoonSprayer"];
