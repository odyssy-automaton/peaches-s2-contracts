import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFn: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, network } = hre;
  const { deployer } = await hre.getNamedAccounts();

  console.log("\nDeploying EthYeeter mock on network:", network.name);

  const shamanDeployed = await deployments.deploy("EthYeeter", {
    contract: "EthYeeter",
    from: deployer,
    args: [],
    // proxy: {
    //     proxyContract: 'UUPS',
    //     methodName: 'initialize',
    // },
    log: true,
  });
  console.log("EthYeeter deployment Tx ->", shamanDeployed.transactionHash);
};

export default deployFn;
deployFn.id = "009_deploy_Mocks_EthYeeter"; // id required to prevent reexecution
deployFn.tags = ["MocksEthYeeter"];
