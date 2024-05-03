// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@daohaus/baal-contracts/contracts/interfaces/IBaal.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PeachTycoonFertilzer is ReentrancyGuard, Initializable, Ownable {
    string public constant name = "PeachTycoonFertilzer";

    uint256 public boostEnd = 1717221600;
    uint256 public boostPrice = 35000000000000000;
    uint256 public boostPriceERC20 = 5000000000000000000000;
    uint256 public boostDiscount = 8750000000000000;
    uint256 public boostDiscountERC20 = 1250000000000000000000;
    address public farmAccount = 0xB1344e792dd923486B7b9665f05454f6A6872A4b; /* Address of farm safe */
    address public farmerCoopAccount = 0xe172278c17F0E58124F2b3201562348FF677c365; /* Address of farmer's coop safe */
    uint256 public farmerCoopCut = 1050000000000000; /* Farmer co-op cut */
    uint256 public farmerCoopCutERC20 = 150000000000000000000; /* Farmer co-op cut */
    uint256 public lootPerBoost = 100000000000000000000; /* Loot per fertilizer */
    uint256 public boostPerToken = 1; /* Ferts per token */
    uint256 public totalFertilizations = 0; /* Count of all ferts */

    IBaal public baal = IBaal(0x1503Bd5f6F082F7fBD36438CC416CD67849c0Bec);
    IERC721 public treeNft = IERC721(0xA9d3c833df8415233e1626F29E33ccBA37d2A187);
    IERC20 public paymentERC20 = IERC20(0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed);
    IERC20 public discountERC20 = IERC20(0xe68E3B3Ee0ce43d55fedCB625D48af4601693a04);

    mapping(uint256 => uint8) public fertilizations; /*maps `tokenId` to fertilizations count*/

    function _mintTokens(address to, uint256 amount) private {
        address[] memory _receivers = new address[](1);
        _receivers[0] = to;

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = amount;
        baal.mintLoot(_receivers, _amounts);
    }

    function fertilize(uint256 _tokenId) public payable nonReentrant {
        require(boostEnd > block.timestamp, "fertlization period has ended");
        require(fertilizations[_tokenId] < boostPerToken, "tree has already been fertlized");
        require(baal.isManager(address(this)), "shaman not manager");
        require(treeNft.ownerOf(_tokenId) == msg.sender, "sender not tree owner");

        uint amountMinusFee = msg.value - farmerCoopCut;

        if (discountERC20.balanceOf(msg.sender) > 0) {
            require(msg.value == (boostPrice - boostDiscount), "incorrect payment amount");
            amountMinusFee -= boostDiscount;
        } else {
            require(msg.value == boostPrice, "incorrect eth payment amount");
        }

        (bool feeSent, ) = farmerCoopAccount.call{ value: farmerCoopCut }("");
        require(feeSent, "Fee not sent");

        (bool sent, ) = farmAccount.call{ value: amountMinusFee }("");
        require(sent, "ETH not sent");

        fertilizations[_tokenId] += 1;
        totalFertilizations += 1;

        _mintTokens(msg.sender, lootPerBoost);
    }

    function fertilizeERC20(uint256 _tokenId, uint256 _amount) public nonReentrant {
        require(boostEnd > block.timestamp, "fertlization period has ended");
        require(fertilizations[_tokenId] < boostPerToken, "tree has already been fertlized");
        require(baal.isManager(address(this)), "shaman not manager");
        require(treeNft.ownerOf(_tokenId) == msg.sender, "sender not tree owner");

        uint amountMinusFee = _amount - farmerCoopCutERC20;

        if (discountERC20.balanceOf(msg.sender) > 0) {
            require(_amount == (boostPriceERC20 - boostDiscountERC20), "incorrect erc20 payment amount");
            amountMinusFee -= boostDiscountERC20;
        } else {
            require(_amount == boostPriceERC20, "incorrect erc20 payment amount");
        }

        require(
            paymentERC20.transferFrom(msg.sender, address(farmerCoopAccount), farmerCoopCutERC20),
            "Fee Transfer failed"
        );

        require(paymentERC20.transferFrom(msg.sender, address(farmAccount), amountMinusFee), "Payment Transfer failed");

        fertilizations[_tokenId] += 1;
        totalFertilizations += 1;

        _mintTokens(msg.sender, lootPerBoost);
    }

    function setboostEnd(uint256 _newboostEnd) public onlyOwner {
        boostEnd = _newboostEnd;
    }

    function setBoostPerToken(uint256 _newBoostPerToken) public onlyOwner {
        boostPerToken = _newBoostPerToken;
    }

    function setPrices(
        uint256 _newBoostPrice,
        uint256 _newBoostPriceERC20,
        uint256 _newBoostDiscount,
        uint256 _newBoostDiscountERC20,
        uint256 _newFarmerCoopCut,
        uint256 _newFarmerCoopCutERC20
    ) public onlyOwner {
        boostPrice = _newBoostPrice;
        boostPriceERC20 = _newBoostPriceERC20;
        boostDiscount = _newBoostDiscount;
        boostDiscountERC20 = _newBoostDiscountERC20;
        farmerCoopCut = _newFarmerCoopCut;
        farmerCoopCutERC20 = _newFarmerCoopCutERC20;
    }
}
