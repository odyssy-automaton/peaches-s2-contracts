import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFn: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, network } = hre;
  const { deployer } = await hre.getNamedAccounts();

  console.log("deployer", deployer);

  console.log("\nDeploying ForgottenFruitBottle on network:", network.name);

  const shamanDeployed = await deployments.deploy("ForgottenFruitBottle", {
    contract: "ForgottenFruitBottle",
    from: deployer,
    args: [],
    // proxy: {
    //     proxyContract: 'UUPS',
    //     methodName: 'initialize',
    // },
    log: true,
  });
  console.log("ForgottenFruitBottle deployment Tx ->", shamanDeployed.transactionHash);
};

export default deployFn;
deployFn.id = "004_deploy_Nfts_ForgottenFruitBottle"; // id required to prevent reexecution
deployFn.tags = ["NftsForgottenFruitBottle"];
