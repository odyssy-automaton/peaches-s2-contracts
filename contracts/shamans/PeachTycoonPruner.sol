// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@daohaus/baal-contracts/contracts/interfaces/IBaal.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// - ownable - what needs to be updated?
// -- -- end date, maybe price and cut?

contract PeachTycoonPruner is ReentrancyGuard, Initializable {
    string public constant name = "PeachTycoonPruner";

    uint256 public pruneEnd = 1715639724;
    uint256 public prunePrice = 1000000000000000;
    uint256 public prunePriceERC20 = 10000000000000000;

    // address public farmAccount = 0xB1344e792dd923486B7b9665f05454f6A6872A4b; /* Address of farm safe */
    address public farmAccount = 0x83aB8e31df35AA3281d630529C6F4bf5AC7f7aBF; /* Address of farm safe */

    // address public farmerCoopAccount = 0xe172278c17F0E58124F2b3201562348FF677c365; /* Address of farmer's coop safe */
    address public farmerCoopAccount = 0x83aB8e31df35AA3281d630529C6F4bf5AC7f7aBF; /* Address of farmer's coop safe */

    uint256 public farmerCoopCut = 100000000000000; /* Farmer co-op cut */
    uint256 public farmerCoopCutERC20 = 100000000000000; /* Farmer co-op cut */
    uint256 public lootPerPrune = 75000000000000000000; /* Farmer co-op cut */

    IBaal public baal = IBaal(0x112e54a494FCA06D71a5b253c9DDdbA6Dc9267FF);
    IERC721 public treeNft = IERC721(0xB49a877D82c1f0133B0293dfd20eB54BEd07a290);
    IERC20 public paymentERC20 = IERC20(0x53c8156592A64E949A4736c6D3309002fa0b2Aba);

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
}
