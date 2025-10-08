// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

/*
  Stake.sol

  Single smart contract that supports:
  - ETH Staking → Earn credits (credits are awarded immediately on deposit at a configurable rate)
  - PACK Purchase → Buy digital packs with ETH
  - NFT Minting → Convert PACKs to NFTs using credits
  - Credit Management → Track and spend credits

  Notes/Assumptions:
  - For simplicity, credits are awarded immediately based on deposited ETH amount using creditsPerEth, rather than over time.
  - Users can later withdraw any staked ETH balance with no penalty using withdrawStake.
  - NFT implementation here is minimal and supports minting and basic ownership queries (ownerOf, balanceOf). Transfers/approvals are intentionally omitted as they are not required for the task.
  - Access control is provided via a simple Ownable pattern implemented locally to avoid external dependencies.
*/

contract Stake is ERC721, Ownable, ReentrancyGuard {
    // ---------- Types ----------
    struct Pack {
        // Price in wei that must be paid in buyPack
        uint256 priceWei; // if 0.01 eth per pack, so 0.01 eth needed to buy 1 pack
        // Credits required when minting an NFT from this pack
        uint256 creditCost; // if 10 credits per pack, so 10 credits needed to convert 1 pack to NFT
        // Whether the pack is active/available for purchase and minting
        bool active;
    }

    // ---------- Events ----------
    event Staked(address indexed user, uint256 amountWei, uint256 creditsAwarded);
    event Unstaked(address indexed user, uint256 amountWei);
    event PackConfigured(uint256 indexed packId, uint256 priceWei, uint256 creditCost, bool active);
    event PackPurchased(address indexed buyer, uint256 indexed packId, uint256 quantity, uint256 totalPaid);
    event MintedFromPack(address indexed minter, uint256 indexed packId, uint256 tokenId, uint256 creditsSpent);
    event WithdrawnProceeds(address indexed to, uint256 amountWei);

    // ---------- Configuration ----------
    // Credits awarded per 1 ETH deposited when staking (scaled linearly for fractions)
    uint256 public creditsPerEth;

    // Mapping of pack id to pack info
    mapping(uint256 => Pack) public packs;

    // ---------- User State ----------
    // Total staked ETH balance
    uint256 public totalStakedWei;
    // User staked ETH balance available for withdrawal
    mapping(address => uint256) public stakedBalanceWei;
    // User available credits balance
    mapping(address => uint256) public creditsOf;
    // User's purchased packs available to convert to NFTs
    mapping(address => mapping(uint256 => uint256)) public userPackBalance;

    // Proceeds attribution when credits are spent (backed by user's staked ETH)
    mapping(address => uint256) public ethEarnedFromSpentCreditsOfUser;

    // ---------- NFT (ERC721) ----------
    // ERC721 itself does not expose total supply without enumerable extension, we can use ERC721Enumerable extension as well though
    uint256 public totalSupply;


    // ---------- Internal ----------
    // Internal function to get the total staked balances
    function _totalStakedBalances() internal view returns (uint256 total) {
        total = totalStakedWei;
    }

    // ---------- Constructor ----------
    constructor(uint256 _creditsPerEth) ERC721("Stake NFT", "SNFT") Ownable(msg.sender) ReentrancyGuard() {
        require(_creditsPerEth > 0, "creditsPerEth=0");
        creditsPerEth = _creditsPerEth;
    }

    // ---------- Owner Admin ----------
    function setCreditsPerEth(uint256 _creditsPerEth) external onlyOwner {
        require(_creditsPerEth > 0, "creditsPerEth=0");
        creditsPerEth = _creditsPerEth;
    }

    function setPack(
        uint256 packId,
        uint256 priceWei,
        uint256 creditCost,
        bool active
    ) external onlyOwner {
        require(creditCost > 0, "creditCost=0");
        packs[packId] = Pack({priceWei: priceWei, creditCost: creditCost, active: active});
        emit PackConfigured(packId, priceWei, creditCost, active);
    }

    /// @notice Withdraw ETH collected from pack purchases (not user stake balances)
    function withdrawProceeds(address payable to, uint256 amountWei) external onlyOwner nonReentrant {
        require(to != address(0), "to=0");
        // Owner can withdraw any ETH that is not reserved as staked balances
        uint256 available = address(this).balance - _totalStakedBalances();
        require(amountWei <= available, "insufficient proceeds");
        (bool ok, ) = to.call{value: amountWei}("");
        require(ok, "transfer failed");
        emit WithdrawnProceeds(to, amountWei);
    }

    /// @notice Returns ETH available for the owner to withdraw (pack purchases + credit conversions)
    function proceedsBalance() external view returns (uint256) {
        return address(this).balance - _totalStakedBalances();
    }

    // ---------- Staking / Credits ----------
    /// @notice Stake ETH to receive credits immediately based on creditsPerEth
    function stake() external payable nonReentrant {
        require(msg.value > 0, "no eth");
        uint256 creditsToAward = (msg.value * creditsPerEth) / 1 ether;
        // check if creditsToAward is greater than 0, as creditsPerEth can be 0 or msg.value can be tiny, if not revet. must get atleast 1 credit.
        require(creditsToAward > 0, "creditsToAward=0");
        stakedBalanceWei[msg.sender] += msg.value;
        creditsOf[msg.sender] += creditsToAward;
        // update the total staked balances 
        totalStakedWei += msg.value;
        
        emit Staked(msg.sender, msg.value, creditsToAward);
    }

    /// @notice Withdraw previously staked ETH
    function withdrawStake(uint256 amountWei) external nonReentrant {
        require(amountWei > 0, "amount=0");
        uint256 bal = stakedBalanceWei[msg.sender];
        require(bal >= amountWei, "insufficient stake");
        stakedBalanceWei[msg.sender] = bal - amountWei;
        totalStakedWei -= amountWei;
        (bool ok, ) = msg.sender.call{value: amountWei}("");
        require(ok, "transfer failed");
        emit Unstaked(msg.sender, amountWei);
    }

    // ---------- PACK Purchase ----------
    /// @notice Buy quantity packs by paying exact price per pack in ETH
    function buyPack(uint256 packId, uint256 quantity) external payable nonReentrant {
        require(quantity > 0, "qty=0");
        Pack memory p = packs[packId];
        require(p.active, "pack inactive");
        uint256 totalPrice = p.priceWei * quantity;
        require(msg.value == totalPrice, "incorrect eth");
        userPackBalance[msg.sender][packId] += quantity;
        emit PackPurchased(msg.sender, packId, quantity, totalPrice);
        // ETH remains in contract as proceeds; owner can withdraw via withdrawProceeds
    }

    // ---------- NFT Minting from Pack ----------
    /// @notice Convert one owned PACK into a newly minted NFT by spending the required credits
    function mintFromPack(uint256 packId) external nonReentrant returns (uint256 tokenId) {
        Pack memory p = packs[packId];
        require(p.active, "pack inactive");
        uint256 availablePacks = userPackBalance[msg.sender][packId];
        require(availablePacks >= 1, "no pack");
        require(creditsOf[msg.sender] >= p.creditCost, "insufficient credits");

        // Convert required credits into an ETH-equivalent amount using the configured exchange rate.
        // This ETH-equivalent is collected as proceeds and removed from the user's staked balance.
        uint256 ethEquivalent = (p.creditCost * 1 ether) / creditsPerEth;
        require(stakedBalanceWei[msg.sender] >= ethEquivalent, "insufficient staked backing");

        // Spend resources: burn one pack and required credits
        userPackBalance[msg.sender][packId] = availablePacks - 1;
        creditsOf[msg.sender] -= p.creditCost;

        // Shift backing ETH from user's staked balance into proceeds (owner-withdrawable)
        stakedBalanceWei[msg.sender] -= ethEquivalent;
        totalStakedWei -= ethEquivalent;
        ethEarnedFromSpentCreditsOfUser[msg.sender] += ethEquivalent;

        // Mint NFT
        tokenId = ++totalSupply;
        _safeMint(msg.sender, tokenId);

        emit MintedFromPack(msg.sender, packId, tokenId, p.creditCost);
    }

}


