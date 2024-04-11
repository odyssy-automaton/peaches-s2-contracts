import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFn: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, network } = hre;
  const { deployer } = await hre.getNamedAccounts();

  console.log("deployer", deployer);

  console.log("\nDeploying PeachTycoonPeachERC721 on network:", network.name);

  const shamanDeployed = await deployments.deploy("PeachTycoonPeachERC721", {
    contract: "PeachTycoonPeachERC721",
    from: deployer,
    args: [],
    // proxy: {
    //     proxyContract: 'UUPS',
    //     methodName: 'initialize',
    // },
    log: true,
  });
  console.log("PeachTycoonPeachERC721 deployment Tx ->", shamanDeployed.transactionHash);
};

export default deployFn;
deployFn.id = "009_deploy_Nfts_PeachTycoonPeachERC721"; // id required to prevent reexecution
deployFn.tags = ["NftsPeachTycoonPeachERC721"];
