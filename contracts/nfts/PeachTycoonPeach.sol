// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PeachTycoonPeachSeason3 is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public redemptionStart = 1754616667; /* Timestamp for activating redemption */
    uint256 public redemptionEnd = 1756663881; /* Timestamp for deactivating redemption */
    bool public mintOpen = true;

    string private _contractURI =
        "ipfs://bafkreiawp7b3zhdpd7ivcn6rt4iihygjcvqzj4yvgllgxoy7mfddmnpzom"; /* URI for the contract metadata */
    string private _baseURIBoxed =
        "ipfs://bafybeie7hm7ytpm5m4n4sjtpszvprviranpjxzeymxv7qsbvpjklqshdyy"; /* baseURI_ String to prepend to boxed token IDs */
    string private _baseURIUnredeemed =
        "ipfs://bafybeidp4avdyhhe7yaern5q4s2kf454vhvskciwv7tdfc6dw5nduo4uoy"; /* baseURI_ String to prepend to unredeemed token IDs */
    string private _baseURIRedeemed =
        "ipfs://bafybeicfbncfmfdhtqgvir2bye76lpeoqd2khn5k7iz5ejgm7otqfycqa4"; /* baseURI_ String to prepend to redeemed token IDs */

    mapping(uint256 => uint8)
        public tokenState; /*  Mapping of tokenID to uint representing state: 0 (boxed), 1 (open), 2 (redeemed) */

    // EVENTS
    event MetadataUpdate(uint256 _tokenId);

    /**
     * @dev Initializes contract
     */
    constructor() ERC721("PeachTycoonPeach", "PEACH") {}

    /**
     * @dev Mints 1 nft to multiple addresses. For minting some tokens to our peach farmers.
     * @param _addresses List of addresses to mint to
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function mintTo(address[] memory _addresses) public onlyOwner {
        require(mintOpen, "Minting has ended");
        for (uint i = 0; i < _addresses.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();

            _safeMint(_addresses[i], tokenId + 1);
            _tokenIdCounter.increment();
        }
    }

    /**
     * @dev Marks tokenID as opened
     * @param _tokenId Timestamp to determine start of sale
     *
     * Requirements:
     * - `tokenId` holder must be function caller
     * - `tokenId` must exist
     * - 'tokenId` must not already be opened
     */
    function unbox(uint256 _tokenId) public {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(tokenState[_tokenId] < 1, "Box is already opened");

        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender, "msg.sender is not the owner of the token");

        tokenState[_tokenId] = 1;

        emit MetadataUpdate(_tokenId);
    }

    /**
     * @dev Marks tokenID as redeemed
     * @param _tokenId Timestamp to determine start of sale
     *
     * Requirements:
     * - `tokenId` holder must be function caller
     * - `tokenId` must exist
     * - 'tokenId` must not already be redeemed
     *  - redemption window must still be open
     */
    function redeem(uint256 _tokenId) public {
        require(redemptionStart <= block.timestamp, "Redemption has not started");
        require(redemptionEnd > block.timestamp, "Redemption has ended");
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(tokenState[_tokenId] == 1, "Token is already redeemed or not opened");

        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender, "msg.sender is not the owner of the token");

        tokenState[_tokenId] = 2;

        emit MetadataUpdate(_tokenId);
    }

    /**
     * @dev Sets the redemptionStart in case peaches are ready early
     * @param _newRedemptionStart redemptionStart for overiding original redemptionStart
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setRedemptionStart(uint256 _newRedemptionStart) public onlyOwner {
        redemptionStart = _newRedemptionStart;
    }

    /**
     * @dev Sets the redemptionEnd in case peaches are ready early
     * @param _newRedemptionEnd redemptionEnd for overiding original redemptionEnd
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setRedemptionEnd(uint256 _newRedemptionEnd) public onlyOwner {
        redemptionEnd = _newRedemptionEnd;
    }

    /**
     * @dev Closes new minting
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setMintEnd() public onlyOwner {
        mintOpen = false;
    }

    /**
     * @dev Sets the baseURIS
     * @param _newBaseURI Metadata URI used for overriding initialBaseURI
     * @param _newBaseURIRedeemed Metadata URI used for overriding initialBaseURIRedeemed
     * @param _newBaseURIBoxed Metadata URI used for overriding initialBaseURIBoxed
     *
     *
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function setBaseURIS(
        string memory _newBaseURI,
        string memory _newBaseURIRedeemed,
        string memory _newBaseURIBoxed
    ) public onlyOwner {
        _baseURIUnredeemed = _newBaseURI;
        _baseURIRedeemed = _newBaseURIRedeemed;
        _baseURIBoxed = _newBaseURIBoxed;
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

        string memory baseURIForToken = _baseURIBoxed;
        if (tokenState[_tokenId] == 1) {
            baseURIForToken = _baseURIUnredeemed;
        }
        if (tokenState[_tokenId] == 2) {
            baseURIForToken = _baseURIRedeemed;
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
