type Contracts = {
  treeErc721: string;
};

type Ownable = {
  owner: string;
};

export const deploymentConfig: { [key: string]: Contracts & Ownable } = {
  "1": {
    // mainnet
    treeErc721: "0x0",
    owner: "",
  },
  "42161": {
    // arbitrum
    treeErc721: "0x0",
    owner: "",
  },
  "10": {
    // optimism
    treeErc721: "0x0",
    owner: "",
  },
  "11155111": {
    // sepolia
    treeErc721: "0x0",
    owner: "",
  },
  "8453": {
    // base
    treeErc721: "0x0",
    owner: "",
  },
}
