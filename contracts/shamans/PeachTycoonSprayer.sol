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

    uint256 public boostEnd = 1717110000;
    uint256 public boostPrice = 1000000000000000;
    uint256 public boostPriceERC20 = 1000000000000000;
    // address public farmAccount = 0xB1344e792dd923486B7b9665f05454f6A6872A4b; /* Address of farm safe */
    // address public farmerCoopAccount = 0xe172278c17F0E58124F2b3201562348FF677c365; /* Address of farmer's coop safe */
    address public farmAccount = 0xf100041473280B594D78AB5Fa4C44Ba81edd367B; /* Address of farm safe */
    address public farmerCoopAccount = 0xf100041473280B594D78AB5Fa4C44Ba81edd367B; /* Address of farmer's coop safe */
    uint256 private farmerCoopCut = 100000000000000; /* Farmer co-op cut */
    uint256 private farmerCoopCutERC20 = 100000000000000; /* Farmer co-op cut */
    uint256 private lootPerBoost = 75000000000000000000; /* Loot per fertilizer */
    uint256 public attemptsPerToken = 2; /* Attempts per token*/
    uint256 public totalSprayWins = 0; /* Count of all spray wins */
    uint256 public totalSprayAttempts = 0; /* Count of all spray attempts */

    uint256 private bugs;

    // IBaal public baal = IBaal(0x1503Bd5f6F082F7fBD36438CC416CD67849c0Bec);
    // IERC721 public treeNft = IERC721(0xA9d3c833df8415233e1626F29E33ccBA37d2A187);
    // IERC20 public paymentERC20 = IERC20(0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed);
    IBaal public baal = IBaal(0x112e54a494FCA06D71a5b253c9DDdbA6Dc9267FF);
    IERC721 public treeNft = IERC721(0xB49a877D82c1f0133B0293dfd20eB54BEd07a290);
    IERC20 public paymentERC20 = IERC20(0x53c8156592A64E949A4736c6D3309002fa0b2Aba);

    mapping(uint256 => uint8) public sprayAttempts; /*maps `tokenId` to spray attempt count*/
    mapping(uint256 => uint8) public sprayWins; /*maps `tokenId` to spray win count*/

    event Sprayed(uint256 tokenId, bool win, uint256 attempt);

    constructor() {
        bugs = block.timestamp % 100;
    }

    function _mintTokens(address to, uint256 amount) private {
        address[] memory _receivers = new address[](1);
        _receivers[0] = to;

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = amount;
        baal.mintLoot(_receivers, _amounts);
    }

    function spray(uint256 _tokenId) public payable nonReentrant {
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
        totalSprayAttempts += 1;

        bool wonRoll = roll();
        if (wonRoll) {
            sprayWins[_tokenId] += 1;
            totalSprayWins += 1;
        }
        _mintTokens(msg.sender, lootPerBoost);

        emit Sprayed(_tokenId, wonRoll, sprayAttempts[_tokenId] - 1);
    }

    function sprayERC20(uint256 _tokenId, uint256 _amount) public nonReentrant {
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
        totalSprayAttempts += 1;

        bool wonRoll = roll();
        if (wonRoll) {
            sprayWins[_tokenId] += 1;
            totalSprayWins += 1;
        }
        _mintTokens(msg.sender, lootPerBoost);

        emit Sprayed(_tokenId, wonRoll, sprayAttempts[_tokenId] - 1);
    }

    function setBoostEnd(uint256 _newBoostEnd) public onlyOwner {
        boostEnd = _newBoostEnd;
    }

    function setAttemptsPerToken(uint256 _newAttemptsPerToken) public onlyOwner {
        attemptsPerToken = _newAttemptsPerToken;
    }

    function roll() private returns (bool) {
        bugs = (bugs + block.timestamp) % 100;
        return bugs <= 33;
    }
}
