// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@daohaus/baal-contracts/contracts/interfaces/IBaal.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PeachTycoonSprayer is ReentrancyGuard, Initializable, Ownable {
    string public constant name = "PeachTycoonSprayer";

    uint256 public boostEnd = 1713830400;
    uint256 public boostPrice = 22000000000000000;
    uint256 public boostPriceERC20 = 5200000000000000000000;
    address public farmAccount = 0xB1344e792dd923486B7b9665f05454f6A6872A4b; /* Address of farm safe */
    address public farmerCoopAccount = 0xe172278c17F0E58124F2b3201562348FF677c365; /* Address of farmer's coop safe */
    uint256 public farmerCoopCut = 660000000000000; /* Farmer co-op cut */
    uint256 public farmerCoopCutERC20 = 156000000000000000000; /* Farmer co-op cut */
    uint256 public lootPerBoost = 75000000000000000000; /* Loot per pruning */
    uint256 public attemptsPerToken = 3; /* Attempts per token*/
    uint256 public totalSprayWins = 0; /* Count of all spary wins */
    uint256 private bugs;

    IBaal public baal = IBaal(0x1503Bd5f6F082F7fBD36438CC416CD67849c0Bec);
    IERC721 public treeNft = IERC721(0xA9d3c833df8415233e1626F29E33ccBA37d2A187);
    IERC20 public paymentERC20 = IERC20(0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed);

    mapping(uint256 => uint8) public sprayAttempts; /*maps `tokenId` to spray attempt count*/
    mapping(uint256 => uint8) public sprayWins; /*maps `tokenId` to spray win count*/

    constructor() {
        bugs = (block.timestamp + block.prevrandao) % 100;
    }

    function _mintTokens(address to, uint256 amount) private {
        address[] memory _receivers = new address[](1);
        _receivers[0] = to;

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = amount;
        baal.mintLoot(_receivers, _amounts);
    }

    function fertilize(uint256 _tokenId) public payable nonReentrant {
        require(boostEnd > block.timestamp, "fertlize period has ended");
        require(msg.value == boostPrice, "incorrect payment amount");
        require(sprayAttempts[_tokenId] < attemptsPerToken, "tree has already been fertlized");
        require(baal.isManager(address(this)), "shaman not manager");
        require(treeNft.ownerOf(_tokenId) == msg.sender, "sender not tree owner");

        uint amountMinusFee = msg.value - farmerCoopCut;

        (bool feeSent, ) = farmerCoopAccount.call{ value: farmerCoopCut }("");
        require(feeSent, "Fee not sent");

        (bool sent, ) = farmAccount.call{ value: amountMinusFee }("");
        require(sent, "ETH not sent");

        sprayAttempts[_tokenId] += 1;

        bool wonRoll = roll();
        if (wonRoll) {
            sprayWins[_tokenId] += 1;
            totalSprayWins += 1;

            _mintTokens(msg.sender, lootPerBoost);
        } else {
            sprayAttempts[_tokenId] += 1;
        }
    }

    function fertilizeERC20(uint256 _tokenId, uint256 _amount) public nonReentrant {
        require(boostEnd > block.timestamp, "fertlize period has ended");
        require(_amount == boostPriceERC20, "incorrect payment amount");
        require(sprayAttempts[_tokenId] < attemptsPerToken, "tree has already been fertlized");
        require(baal.isManager(address(this)), "shaman not manager");
        require(treeNft.ownerOf(_tokenId) == msg.sender, "sender not tree owner");

        uint amountMinusFee = _amount - farmerCoopCutERC20;

        require(
            paymentERC20.transferFrom(msg.sender, address(farmerCoopAccount), farmerCoopCutERC20),
            "Fee Transfer failed"
        );

        require(paymentERC20.transferFrom(msg.sender, address(farmAccount), amountMinusFee), "Payment Transfer failed");

        sprayAttempts[_tokenId] += 1;

        bool wonRoll = roll();
        if (wonRoll) {
            sprayWins[_tokenId] += 1;
            totalSprayWins += 1;

            _mintTokens(msg.sender, lootPerBoost);
        }
    }

    function setboostEnd(uint256 _newboostEnd) public onlyOwner {
        boostEnd = _newboostEnd;
    }

    function roll() private returns (bool) {
        bugs = (bugs + block.timestamp + block.prevrandao) % 100;
        return bugs <= 33;
    }
}
