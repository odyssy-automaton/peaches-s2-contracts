// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ForgottenFruitBottle is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public redemptionStart = 1721066400; /* Timestamp for activating redemption */
    uint256 public redemptionEnd = 1725116400; /* Timestamp for deactivating redemption */
    bool public mintOpen = true;
    uint256 public mintPrice = 10000000000000000; /* Mint price of each token */
    uint256 public maxSupply = 420; /* Max supply of tokens */
    address public farmAccount = 0xB1344e792dd923486B7b9665f05454f6A6872A4b; /* Address of farm safe */

    string private _contractURI =
        "ipfs://QmazcTRtuwT6XFqaqjZd7xuDmE1p2es8Cngm9otG5fCSYU"; /* URI for the contract metadata */
    string private _baseURIUnredeemed =
        "ipfs://QmXgLFvzKVAkNRLYFeJP9joJjQgQWyxjPrrW9zZxx3rGHQ"; /* baseURI_ String to prepend to unredeemed token IDs */
    string private _baseURIRedeemed =
        "ipfs://QmRTiEfKwqoAJyP8xaAU6LWMDWR3MVsvTZGZPECP6R8N9X"; /* baseURI_ String to prepend to redeemed token IDs */

    mapping(uint256 => uint8)
        public tokenState; /*  Mapping of tokenID to uint representing state: 0 (unredeemed), 1 (redeemed) */

    // EVENTS
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /**
     * @dev Initializes contract
     */
    constructor() ERC721("ForgottenFruitBottle", "FORGOTTENFRUIT") {}

    /**
     * @dev Mints 1 nft to sender
     * Requirements:
     *
     * - `msg.value` must be exact payment amount in wei
     * - `nextTokenID must be less than the `maxSupply`
     * - `deactivationTimestamp` must be greater than the current block time
     */
    function mint() public payable {
        require(mintPrice == msg.value, "Incorrect payment amount");
        require(mintOpen, "Minting has ended");

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "No more tokens available to mint");

        (bool sent, ) = farmAccount.call{ value: msg.value }("");
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
        require(mintOpen, "Minting has ended");
        for (uint i = 0; i < _addresses.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            require(tokenId < maxSupply, "No more tokens available to mint");

            _safeMint(_addresses[i], tokenId + 1);
            _tokenIdCounter.increment();
        }
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
        require(tokenState[_tokenId] == 0, "Token is already redeemed");

        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender, "msg.sender is not the owner of the token");

        tokenState[_tokenId] = 1;

        emit MetadataUpdate(_tokenId);
    }

    /**
     * @dev Marks tokenIDs as redeemed
     * @param _tokenIds Array of tokenIds to mark redeemed
     *
     * Requirements:
     * - `owner` must be function caller
     * - `tokenId` must exist
     * - 'tokenId` must not already be redeemed
     *  - minting/redemption window must still be open
     */
    function batchRedeem(uint256[] memory _tokenIds) public onlyOwner {
        require(redemptionStart <= block.timestamp, "Redemption has not started");
        require(redemptionEnd > block.timestamp, "Redemption has ended");

        for (uint i = 0; i < _tokenIds.length; i++) {
            if (_exists(_tokenIds[i])) {
                tokenState[_tokenIds[i]] = 1;
            }
        }

        emit BatchMetadataUpdate(0, _tokenIdCounter.current());
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
     * @dev Sets new mint price
     * @param _newPrice new price for a mint
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    /**
     * @dev Sets the baseURIS
     * @param _newBaseURI Metadata URI used for overriding initialBaseURI
     * @param _newBaseURIRedeemed Metadata URI used for overriding initialBaseURIRedeemed
     *
     *
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function setBaseURIS(string memory _newBaseURI, string memory _newBaseURIRedeemed) public onlyOwner {
        _baseURIUnredeemed = _newBaseURI;
        _baseURIRedeemed = _newBaseURIRedeemed;
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

        string memory baseURIForToken = _baseURIUnredeemed;
        if (tokenState[_tokenId] == 1) {
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
