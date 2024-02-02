// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SnackERC721 is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Timestamp for activating minting
    uint256 public activationTimestamp = 1688367660;

    // Timestamp for deactivating mint
    uint256 public deactivationTimestamp = 1709402891;

    // Address of farm safe
    address public beneficiary = 0xEB8C7E21b847a7B9CA33209e9e4EdCc5e45054b4;

    // Max supply of total tokens
    uint256 public maxSupply = 50;

    // Mint price of each token
    uint256 public mintPrice = 1000000000000000;

    // URI for the contract metadata
    string private _contractURI = "ipfs://QmSLUeCuGtbWvm5zbTqBRfnJWr7nqmW9hf1bC3Fci5rRNs";

    // baseURI_ String to prepend to token IDs
    string private baseURI = "ipfs://QmagNNffG2oGEcydVxoFEqfjrLSc55XdhwZu4eC4hnTPwe";

    // Indicates if Metadata uri is frozen
    bool public metdataFrozen = false;

    /**
     * @dev Initializes contract
     */
    constructor() ERC721("Snacks", "SNACK") {}

    /**
     * @dev Mints token to sender
     * Requirements:
     *
     * - `msg.value` must be exact payment amount in wei
     * - `nextTokenID must be less than the `maxSupply`
     * - `deactivationTimestamp` must be greater than the current block time
     */
    function mint() public payable {
        require(mintPrice == msg.value, "Incorrect payment amount");
        require(deactivationTimestamp > block.timestamp, "Minting has ended");

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "No more tokens available to mint");

        (bool sent, ) = beneficiary.call{ value: msg.value }("");
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
        require(deactivationTimestamp > block.timestamp, "Minting has ended");
        for (uint i = 0; i < _addresses.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            require(tokenId < maxSupply, "No more tokens available to mint");

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
     * @dev Sets the activationTimestap in case peaches are ready early
     * @param _newActivationTimestamp activationTimestap for overiding original activationTimestap
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setActivationTimestamp(uint256 _newActivationTimestamp) public onlyOwner {
        activationTimestamp = _newActivationTimestamp;
    }

    /**
     * @dev Sets the deactivationTimestap in case peach availability runs late
     * @param _newDeactivationTimestamp deactivationTimestap for overiding original deactivationTimestap
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setDeactivationTimestamp(uint256 _newDeactivationTimestamp) public onlyOwner {
        deactivationTimestamp = _newDeactivationTimestamp;
    }

    /**
     * @dev Sets the baseURI
     * @param _newBaseURI Metadata URI used for overriding initialBaseURI
     * @param _isRedeemSetter Indicates if is the final URI setting for redeemed tokenIds. Will freeze metadata.
     *
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function setBaseURI(string memory _newBaseURI, bool _isRedeemSetter) public onlyOwner {
        baseURI = _newBaseURI;
        if (_isRedeemSetter) {
            setMetadataFrozen();
        }
    }

    /**
     * @dev Sets the metdataFrozen to true
     * TODO: event?
     */
    function setMetadataFrozen() private {
        metdataFrozen = true;
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

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId), ".json"))
                : "";
    }

    /**
     * @dev Returns the contract uri metadata
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev See {IERC721-baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the current tokenID
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
}
