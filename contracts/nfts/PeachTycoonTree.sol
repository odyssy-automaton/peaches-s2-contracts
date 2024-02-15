// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PeachTycoonTreeERC721 is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public mintStart = 1688367660; /* Timestamp for activating minting */
    uint256 public mintEnd = 1709402891; /* Timestamp for deactivating mint */
    address public farmAccount = 0xEB8C7E21b847a7B9CA33209e9e4EdCc5e45054b4; /* Address of farm safe */
    address public farmerCoopAccount = 0xEB8C7E21b847a7B9CA33209e9e4EdCc5e45054b4; /* Address of farmer's coop safe */
    uint256 public mintPrice = 1000000000000000; /* Mint price of each token */
    uint256 public farmerCoopCut = 10000000000000; /* Farmer co-op cut */
    uint8 public season = 0;
    /* seasons for metadata toggle
    0 = spring
    1 = summer
    2 = harvest
    3 = winter */

    string private _contractURI =
        "ipfs://QmSLUeCuGtbWvm5zbTqBRfnJWr7nqmW9hf1bC3Fci5rRNs"; /* URI for the contract metadata */
    string private springBaseURI = ""; /* tokenuri to prepend to token ids in the spring season */
    string private summerBaseURI = ""; /* tokenuri to prepend to token ids in the summer season */
    string private harvestBaseURI = ""; /* tokenuri to prepend to token ids in the harvest season */
    string private winterBaseURI = ""; /* tokenuri to prepend to token ids in the winter season */

    // EVENTS
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    // To refresh a whole collection, emit _toTokenId with type(uint256).max

    /**
     * @dev Initializes contract
     */
    constructor() ERC721("PeachTycoonTree", "TREE") {}

    /**
     * @dev Mints token to sender
     * Requirements:
     *
     * - `msg.value` must be exact payment amount in wei
     * - `mintStart` must be greater than the current block time
     */
    function mint() public payable {
        require(mintPrice == msg.value, "Incorrect payment amount");
        require(mintStart > block.timestamp, "Minting has ended");

        uint256 tokenId = _tokenIdCounter.current();

        uint amountMinusFee = msg.value - farmerCoopCut;

        (bool feeSent, ) = farmAccount.call{ value: farmerCoopCut }("");
        require(feeSent, "Fee not sent");

        (bool sent, ) = farmAccount.call{ value: amountMinusFee }("");
        require(sent, "ETH not sent");

        _safeMint(msg.sender, tokenId + 1);
        _tokenIdCounter.increment();
    }

    /**
     * @dev Mints 1 nft to multiple addresses. For minting some tokens to our peach farmers.
     * @param _addresses List of addresses to mint to
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function mintTo(address[] memory _addresses) public onlyOwner {
        require(mintStart > block.timestamp, "Minting has ended");
        for (uint i = 0; i < _addresses.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();

            _safeMint(_addresses[i], tokenId + 1);
            _tokenIdCounter.increment();
        }
    }

    /**
     * @dev Sets the price
     * @param _newPrice Price for overiding original price
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    /**
     * @dev Sets the mintStart in case peaches are ready early
     * @param _newMintStart mintStart for overiding original mintStart
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setMintStart(uint256 _newMintStart) public onlyOwner {
        mintStart = _newMintStart;
    }

    /**
     * @dev Sets the mintEnd in case peach availability runs late
     * @param _newMintEnd mintEnd for overiding original mintEnd
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setMintEnd(uint256 _newMintEnd) public onlyOwner {
        mintEnd = _newMintEnd;
    }

    /**
     * @dev Sets the season
     * @param _newSeason season unit8 for overiding original season unit8
     *
     * Requirements:
     * - `owner` must be function caller
     * - `_newSeason` must be a valid season
     *
     */
    function setSeason(uint8 _newSeason) public onlyOwner {
        require(_newSeason > 4, "invalid season");
        season = _newSeason;
    }

    /**
     * @dev Sets the baseURIS
     * @param _newSpringBaseURI Metadata URI used for overriding springBaseURI
     * @param _newSummerBaseURI Metadata URI used for overriding summerBaseURI
     * @param _newHarvestBaseURI Metadata URI used for overriding harvestBaseURI
     * @param _newWinterBaseURI Metadata URI used for overriding winterBaseURI
     *
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function setBaseURIS(
        string memory _newSpringBaseURI,
        string memory _newSummerBaseURI,
        string memory _newHarvestBaseURI,
        string memory _newWinterBaseURI
    ) public onlyOwner {
        springBaseURI = _newSpringBaseURI;
        summerBaseURI = _newSummerBaseURI;
        harvestBaseURI = _newHarvestBaseURI;
        winterBaseURI = _newWinterBaseURI;
    }

    /**
     * @dev Sets the contractURI
     * @param _newContractURI Metadata URI used for overriding contract URI
     *
     *
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function setContractURI(string memory _newContractURI) public onlyOwner {
        _contractURI = _newContractURI;
    }

    /**
     * @dev Returns the tokenURI for a given tokenID
     * @param _tokenId tokenId
     * Requirements:
     *
     * - `tokenId` must exist
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURIForToken = springBaseURI;
        if (season == 1) {
            baseURIForToken = summerBaseURI;
        }
        if (season == 2) {
            baseURIForToken = harvestBaseURI;
        }
        if (season == 3) {
            baseURIForToken = winterBaseURI;
        }

        return
            bytes(baseURIForToken).length > 0
                ? string(abi.encodePacked(baseURIForToken, "/", Strings.toString(_tokenId), ".json"))
                : "";
    }

    /**
     * @dev Returns the contract uri metadata
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns the current tokenID
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
}
