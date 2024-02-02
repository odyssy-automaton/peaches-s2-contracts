import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFn: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, network } = hre;
  const { deployer } = await hre.getNamedAccounts();

  console.log("\nDeploying SnackERC721 mock on network:", network.name);

  const shamanDeployed = await deployments.deploy("SnackERC721", {
    contract: "SnackERC721",
    from: deployer,
    args: [],
    // proxy: {
    //     proxyContract: 'UUPS',
    //     methodName: 'initialize',
    // },
    log: true,
  });
  console.log("SnackERC721 deployment Tx ->", shamanDeployed.transactionHash);
};

export default deployFn;
deployFn.id = "009_deploy_Mocks_SnackERC721"; // id required to prevent reexecution
deployFn.tags = ["MocksSnackERC721"];
