// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../utils/base64.sol";

contract PeachTycoonTreeSeason3 is ReentrancyGuard, ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public mintEnd = 1754687716; /* Timestamp for deactivating mint */
    address public farmAccount = 0xB1344e792dd923486B7b9665f05454f6A6872A4b; /* Address of farm safe */
    address public farmerCoopAccount = 0xe172278c17F0E58124F2b3201562348FF677c365; /* Address of farmer's coop safe */
    uint256 public maxSupply = 150; /* Max token supply available to mint*/
    uint256 public mintPrice = 200000000000000000; /* Mint price of each token */
    uint256 public erc20MintPrice = 300000000; /* ERC20 Mint price of each token */
    uint256 public mintDiscountPerc = 10;
    uint256 public farmerCoopCutPerc = 3;
    uint8 public currentSeason = 0; /* seasons for metadata toggle */
    string private _contractURI =
        "ipfs://bafkreih5xgygtnavv5cg4ywt45l524yvrfu4hn23uicik7x3rot3ubaoau"; /* URI for the contract metadata */
    string private baseURI =
        "ipfs://bafybeic5dpqs7m4ivzllbxsp5xxr3n7gefz3aucieubmurznzuanmrkvji"; /* url to build token images */
    string[] private trunks = ["MF Bloom", "Warren Tree", "Notorious P.E.A.C.H."];
    string[] private critters = ["None", "Bear", "Fox", "Racoon", "Sack", "Squirrel", "Wine Barrel", "Eagle", "Crow"];
    string[] private seasons = ["Winter", "Spring", "Summer", "Harvest"];

    IERC721 public season2TreeNft = IERC721(0xA9d3c833df8415233e1626F29E33ccBA37d2A187);
    IERC20 public paymentERC20 = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

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
    function mint(uint8 _trunkId, uint8 _critterId) public payable nonReentrant {
        require(mintEnd > block.timestamp, "Minting has ended");
        require(_trunkId < 3, "Invalid trunk");
        require(_critterId < 9, "Invalid critter");

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "No more tokens available to mint");

        uint256 amountMinusFee;
        uint256 farmerCoopCut;
        if (season2TreeNft.balanceOf(msg.sender) > 0) {
            uint256 discountMintPrice = subtractPercent(mintPrice, mintDiscountPerc);
            require(msg.value == discountMintPrice, "incorrect payment amount");
            farmerCoopCut = subtractPercent(discountMintPrice, farmerCoopCutPerc);
        } else {
            require(msg.value == mintPrice, "incorrect eth payment amount");
            farmerCoopCut = subtractPercent(mintPrice, farmerCoopCutPerc);
        }
        amountMinusFee = msg.value - farmerCoopCut;

        (bool feeSent, ) = farmerCoopAccount.call{ value: farmerCoopCut }("");
        require(feeSent, "Fee not sent");

        (bool sent, ) = farmAccount.call{ value: amountMinusFee }("");
        require(sent, "ETH not sent");

        _safeMint(msg.sender, tokenId + 1);
        _tokenIdCounter.increment();
        tokenMetas[tokenId + 1] = TokenMeta(_trunkId, _critterId);
    }

    /**
     * @dev Mints token to sender using erc20 for payment
     * @param _trunkId id of the trunk type
     * @param _critterId id of the critter
     * @param _amount erc20 amount for mint
     *
     *
     * Requirements:
     *
     * - `msg.value` must be exact payment amount in wei
     * - `mintStart` must be greater than the current block time
     * - `trunkId` must be less than 2
     * - `critterId` must be less than 5
     */
    function mintERC20(uint8 _trunkId, uint8 _critterId, uint256 _amount) public nonReentrant {
        require(mintEnd > block.timestamp, "Minting has ended");
        require(_trunkId < 3, "Invalid trunk");
        require(_critterId < 9, "Invalid critter");

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "No more tokens available to mint");

        uint256 amountMinusFee;
        uint256 farmerCoopCut;
        if (season2TreeNft.balanceOf(msg.sender) > 0) {
            uint256 discountMintPrice = subtractPercent(erc20MintPrice, mintDiscountPerc);
            require(_amount == discountMintPrice, "incorrect payment amount");
            farmerCoopCut = subtractPercent(discountMintPrice, farmerCoopCutPerc);
        } else {
            require(_amount == erc20MintPrice, "incorrect erc20 payment amount");
            farmerCoopCut = subtractPercent(erc20MintPrice, farmerCoopCutPerc);
        }
        amountMinusFee = _amount - farmerCoopCut;

        require(
            paymentERC20.transferFrom(msg.sender, address(farmerCoopAccount), farmerCoopCut),
            "Fee Transfer failed"
        );

        require(paymentERC20.transferFrom(msg.sender, address(farmAccount), amountMinusFee), "Payment Transfer failed");

        _safeMint(msg.sender, tokenId + 1);
        _tokenIdCounter.increment();
        tokenMetas[tokenId + 1] = TokenMeta(_trunkId, _critterId);
    }

    /**
     * @dev Sets the price
     * @param _newPrice Price for overiding original price
     * @param _newMintDiscountPerc new percentage for mint discount
     * @param _newFarmerCoopCutPerc Cut perc for overiding original cut
     *
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setPrice(uint256 _newPrice, uint256 _newMintDiscountPerc, uint256 _newFarmerCoopCutPerc) public onlyOwner {
        mintPrice = _newPrice;
        mintDiscountPerc = _newMintDiscountPerc;
        farmerCoopCutPerc = _newFarmerCoopCutPerc;
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
        require(_newSeason < 4, "invalid season");
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
                '{"name": "Peach Tycoon Season 3 Tree #',
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

    /**
     * @dev Subtracts a percentage from a value
     * @param value The base value
     * @param percentage The percentage to subtract (between 0 and 100)
     * @return The value after subtracting the percentage
     */
    function subtractPercent(uint256 value, uint256 percentage) internal pure returns (uint256) {
        require(percentage <= 100, "Percentage must be between 0 and 100");
        uint256 amountToSubtract = (value * percentage) / 100;
        return value - amountToSubtract;
    }
}
