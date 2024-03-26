// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@daohaus/baal-contracts/contracts/interfaces/IBaal.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PeachTycoonPruner is ReentrancyGuard, Initializable, Ownable {
    string public constant name = "PeachTycoonPruner";

    uint256 public pruneEnd = 1713830400;
    uint256 public prunePrice = 22000000000000000;
    uint256 public prunePriceERC20 = 5200000000000000000000;
    address public farmAccount = 0xB1344e792dd923486B7b9665f05454f6A6872A4b; /* Address of farm safe */
    address public farmerCoopAccount = 0xe172278c17F0E58124F2b3201562348FF677c365; /* Address of farmer's coop safe */
    uint256 public farmerCoopCut = 660000000000000; /* Farmer co-op cut */
    uint256 public farmerCoopCutERC20 = 156000000000000000000; /* Farmer co-op cut */
    uint256 public lootPerPrune = 75000000000000000000; /* Loot per pruning */

    IBaal public baal = IBaal(0x1503Bd5f6F082F7fBD36438CC416CD67849c0Bec);
    IERC721 public treeNft = IERC721(0xA9d3c833df8415233e1626F29E33ccBA37d2A187);
    IERC20 public paymentERC20 = IERC20(0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed);

    mapping(uint256 => uint8) public prunings; /*maps `tokenId` to prunings count*/

    function _mintTokens(address to, uint256 amount) private {
        address[] memory _receivers = new address[](1);
        _receivers[0] = to;

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = amount;
        baal.mintLoot(_receivers, _amounts);
    }

    function prune(uint256 _tokenId) public payable nonReentrant {
        require(pruneEnd > block.timestamp, "prune period has ended");
        require(msg.value == prunePrice, "incorrect payment amount");
        require(prunings[_tokenId] < 1, "tree has already been pruned");
        require(baal.isManager(address(this)), "shaman not manager");
        require(treeNft.ownerOf(_tokenId) == msg.sender, "sender not tree owner");

        uint amountMinusFee = msg.value - farmerCoopCut;

        (bool feeSent, ) = farmerCoopAccount.call{ value: farmerCoopCut }("");
        require(feeSent, "Fee not sent");

        (bool sent, ) = farmAccount.call{ value: amountMinusFee }("");
        require(sent, "ETH not sent");

        prunings[_tokenId] = 1;

        _mintTokens(msg.sender, lootPerPrune);
    }

    function pruneERC20(uint256 _tokenId, uint256 _amount) public nonReentrant {
        require(pruneEnd > block.timestamp, "prune period has ended");
        require(_amount == prunePriceERC20, "incorrect payment amount");
        require(prunings[_tokenId] < 1, "tree has already been pruned");
        require(baal.isManager(address(this)), "shaman not manager");
        require(treeNft.ownerOf(_tokenId) == msg.sender, "sender not tree owner");

        uint amountMinusFee = _amount - farmerCoopCutERC20;

        require(
            paymentERC20.transferFrom(msg.sender, address(farmerCoopAccount), farmerCoopCutERC20),
            "Fee Transfer failed"
        );

        require(paymentERC20.transferFrom(msg.sender, address(farmAccount), amountMinusFee), "Payment Transfer failed");

        prunings[_tokenId] = 1;

        _mintTokens(msg.sender, lootPerPrune);
    }

    function setPruneEnd(uint256 _newPruneEnd) public onlyOwner {
        pruneEnd = _newPruneEnd;
    }

    function setPrice(
        uint256 _newPrunePrice,
        uint256 _newPrunePriceERC20,
        uint256 _newFarmerCoopCut,
        uint256 _newFarmerCoopCutERC20
    ) public onlyOwner {
        prunePrice = _newPrunePrice;
        prunePriceERC20 = _newPrunePriceERC20;
        farmerCoopCut = _newFarmerCoopCut;
        farmerCoopCutERC20 = _newFarmerCoopCutERC20;
    }
}
