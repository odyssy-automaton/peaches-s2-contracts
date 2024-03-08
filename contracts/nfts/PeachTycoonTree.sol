// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./base64.sol";

contract PeachTycoonTreeERC721 is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public mintStart = 1709341200; /* Timestamp for activating minting */
    uint256 public mintEnd = 1714608000; /* Timestamp for deactivating mint */
    address public farmAccount = 0xB1344e792dd923486B7b9665f05454f6A6872A4b; /* Address of farm safe */
    address public farmerCoopAccount = 0xe172278c17F0E58124F2b3201562348FF677c365; /* Address of farmer's coop safe */
    uint256 public maxSupply = 200; /* Max token supply available to mint*/
    uint256 public mintPrice = 88800000000000000; /* Mint price of each token */
    uint256 public farmerCoopCut = 2664000000000000; /* Farmer co-op cut */
    uint8 public currentSeason = 0; /* seasons for metadata toggle */
    string private _contractURI =
        "ipfs://QmP6cbCzEJprWe56XJG6hoDv9WUjBonRoybE2UK27LvgSd"; /* URI for the contract metadata */
    string private baseURI = "ipfs://QmbCivk5YRHrCn9U1VR9cQPz9ZRiGijvPBbRw5ayB5uPUc"; /* url to build token images */
    string[] private trunks = ["The Proud Peacher", "Peachicus Magnificus", unicode"Big ol` Peachy"];
    string[] private critters = ["None", "Bear", "Fox", "Racoon", "Squirrel", "Butterfly", "Hummingbird"];
    string[] private seasons = ["Winter", "Spring", "Summer"];

    mapping(uint256 => TokenMeta) public tokenMetas; /*maps `tokenId` to struct details*/

    // DATA STRUCTURES
    struct TokenMeta {
        uint8 trunkId /*indicator of the trunk type/name*/;
        uint8 critterId /*indicator of the critter name*/;
    }

    // EVENTS
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /**
     * @dev Initializes contract
     */
    constructor() ERC721("PeachTycoonTree", "TREE") {}

    /**
     * @dev Mints token to sender
     * @param _trunkId id of the trunk type
     * @param _critterId id of the critter
     *
     * Requirements:
     *
     * - `msg.value` must be exact payment amount in wei
     * - `mintStart` must be greater than the current block time
     * - `trunkId` must be less than 2
     * - `critterId` must be less than 5
     */
    function mint(uint8 _trunkId, uint8 _critterId) public payable {
        require(mintPrice == msg.value, "Incorrect payment amount");
        require(mintStart <= block.timestamp, "Minting has not started");
        require(mintEnd > block.timestamp, "Minting has ended");
        require(_trunkId < 3, "Invalid trunk");
        require(_critterId < 7, "Invalid critter");

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "No more tokens available to mint");

        uint amountMinusFee = msg.value - farmerCoopCut;

        (bool feeSent, ) = farmerCoopAccount.call{ value: farmerCoopCut }("");
        require(feeSent, "Fee not sent");

        (bool sent, ) = farmAccount.call{ value: amountMinusFee }("");
        require(sent, "ETH not sent");

        _safeMint(msg.sender, tokenId + 1);
        _tokenIdCounter.increment();
        tokenMetas[tokenId + 1] = TokenMeta(_trunkId, _critterId);
    }

    /**
     * @dev Sets the price
     * @param _newPrice Price for overiding original price
     * @param _newFarmerCoopCut Cut for overiding original cut
     *
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setPrice(uint256 _newPrice, uint256 _newFarmerCoopCut) public onlyOwner {
        mintPrice = _newPrice;
        farmerCoopCut = _newFarmerCoopCut;
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
        require(_newSeason < 3, "invalid season");
        currentSeason = _newSeason;

        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    /**
     * @dev Sets the baseURI
     * @param _newBaseURI Metadata URI used for overriding baseURI
     *
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;

        emit BatchMetadataUpdate(1, type(uint256).max);
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

        string memory seasonName = seasons[currentSeason];
        string memory trunkName = trunks[tokenMetas[_tokenId].trunkId];
        string memory critterName = critters[tokenMetas[_tokenId].critterId];

        string memory imgPath = string(
            abi.encodePacked(
                baseURI,
                "/",
                seasonName,
                "/",
                Strings.toString(tokenMetas[_tokenId].trunkId),
                "/",
                Strings.toString(tokenMetas[_tokenId].critterId),
                ".png"
            )
        );

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "Peach Tycoon Tree #',
                Strings.toString(_tokenId),
                '", "description": "',
                trunkName,
                '", "image": "',
                imgPath,
                '", "external_url": "https://peachtycoon.com", "attributes":',
                '[{"trait_type": "Name", "value":"',
                trunkName,
                '"}, {"trait_type": "Critter", "value":"',
                critterName,
                '"}, {"trait_type": "Season", "value":"',
                seasonName,
                '"}]}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata))));
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
