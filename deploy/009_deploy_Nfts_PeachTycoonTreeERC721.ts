import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFn: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, network } = hre;
  const { deployer } = await hre.getNamedAccounts();

  console.log("\nDeploying PeachTycoonTreeERC721 on network:", network.name);

  const shamanDeployed = await deployments.deploy("PeachTycoonTreeERC721", {
    contract: "PeachTycoonTreeERC721",
    from: deployer,
    args: [],
    // proxy: {
    //     proxyContract: 'UUPS',
    //     methodName: 'initialize',
    // },
    log: true,
  });
  console.log("PeachTycoonTreeERC721 deployment Tx ->", shamanDeployed.transactionHash);
};

export default deployFn;
deployFn.id = "009_deploy_Nfts_PeachTycoonTreeERC721"; // id required to prevent reexecution
deployFn.tags = ["NftsPeachTycoonTreeERC721"];
