// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;

/*
  Stake.sol - TRON Compatible Version (Solidity 0.5.x)

  CRITICAL: TRON's TVM fully supports Solidity 0.5.x
  Solidity 0.8.x opcodes are NOT fully compatible with TRON
  
  Changes for 0.5.x compatibility:
  1. No SafeMath overflow checks (must add manual checks)
  2. Must use `address(uint160(...))` for address conversions
  3. Constructor syntax: constructor() public
  4. payable(address) doesn't exist - use address directly
*/

contract Stake2 {
    // ---------- ERC721 Base ----------
    string public name = "Stake NFT";
    string public symbol = "SNFT";
    
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    // ---------- Access Control ----------
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // ---------- ReentrancyGuard ----------
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    modifier nonReentrant() {
        require(_status != _ENTERED, "reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    // ---------- Pack Storage ----------
    mapping(uint256 => uint256) public packPriceWei;
    mapping(uint256 => uint256) public packCreditCost;
    mapping(uint256 => bool) public packActive;

    // ---------- Events ----------
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Staked(address indexed user, uint256 amountWei, uint256 creditsAwarded);
    event Unstaked(address indexed user, uint256 amountWei);
    event PackConfigured(uint256 indexed packId, uint256 priceWei, uint256 creditCost, bool active);
    event PackPurchased(address indexed buyer, uint256 indexed packId, uint256 quantity, uint256 totalPaid);
    event MintedFromPack(address indexed minter, uint256 indexed packId, uint256 tokenId, uint256 creditsSpent);
    event WithdrawnProceeds(address indexed to, uint256 amountWei);

    // ---------- Configuration ----------
    uint256 public creditsPerEth;

    // ---------- User State ----------
    uint256 public totalStakedWei;
    mapping(address => uint256) public stakedBalanceWei;
    mapping(address => uint256) public creditsOf;
    mapping(address => mapping(uint256 => uint256)) public userPackBalance;
    mapping(address => uint256) public ethEarnedFromSpentCreditsOfUser;

    // ---------- NFT ----------
    uint256 public totalSupply;

    // ---------- Constructor ----------
    constructor(uint256 _creditsPerEth) public {
        require(_creditsPerEth > 0, "creditsPerEth=0");
        owner = msg.sender;
        creditsPerEth = _creditsPerEth;
        _status = _NOT_ENTERED;
    }

    // ---------- SafeMath (Required for 0.5.x) ----------
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "overflow");
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "underflow");
        return a - b;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "overflow");
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div by zero");
        return a / b;
    }

    // ---------- ERC721 Implementation ----------
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "zero address");
        return _balances[_owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address tokenOwner = _owners[tokenId];
        require(tokenOwner != address(0), "nonexistent token");
        return tokenOwner;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "mint to zero");
        require(!_exists(tokenId), "already minted");

        _balances[to] = safeAdd(_balances[to], 1);
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // ---------- Internal ----------
    function _totalStakedBalances() internal view returns (uint256) {
        return totalStakedWei;
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
        
        packPriceWei[packId] = priceWei;
        packCreditCost[packId] = creditCost;
        packActive[packId] = active;
        
        emit PackConfigured(packId, priceWei, creditCost, active);
    }

    function withdrawProceeds(address payable to, uint256 amountWei) external onlyOwner nonReentrant {
        require(to != address(0), "to=0");
        uint256 available = safeSub(address(this).balance, _totalStakedBalances());
        require(amountWei <= available, "insufficient proceeds");
        
        (bool success, ) = to.call.value(amountWei)("");
        require(success, "transfer failed");
        
        emit WithdrawnProceeds(to, amountWei);
    }

    function proceedsBalance() external view returns (uint256) {
        return safeSub(address(this).balance, _totalStakedBalances());
    }

    // ---------- Pack Info View ----------
    function getPack(uint256 packId) external view returns (
        uint256 priceWei,
        uint256 creditCost,
        bool active
    ) {
        return (
            packPriceWei[packId],
            packCreditCost[packId],
            packActive[packId]
        );
    }

    // ---------- Staking / Credits ----------
    function stake() external payable nonReentrant {
        require(msg.value > 0, "no eth");
        
        uint256 creditsToAward = safeDiv(safeMul(msg.value, creditsPerEth), 1000000);
        require(creditsToAward > 0, "creditsToAward=0");
        
        stakedBalanceWei[msg.sender] = safeAdd(stakedBalanceWei[msg.sender], msg.value);
        creditsOf[msg.sender] = safeAdd(creditsOf[msg.sender], creditsToAward);
        totalStakedWei = safeAdd(totalStakedWei, msg.value);
        
        emit Staked(msg.sender, msg.value, creditsToAward);
    }

    function withdrawStake(uint256 amountWei) external nonReentrant {
        require(amountWei > 0, "amount=0");
        
        uint256 bal = stakedBalanceWei[msg.sender];
        require(bal >= amountWei, "insufficient stake");
        
        stakedBalanceWei[msg.sender] = safeSub(bal, amountWei);
        totalStakedWei = safeSub(totalStakedWei, amountWei);
        
        (bool success, ) = msg.sender.call.value(amountWei)("");
        require(success, "transfer failed");
        
        emit Unstaked(msg.sender, amountWei);
    }

    // ---------- PACK Purchase ----------
    function buyPack(uint256 packId, uint256 quantity) external payable nonReentrant {
        require(quantity > 0, "qty=0");
        require(packActive[packId], "pack inactive");
        
        uint256 priceWei = packPriceWei[packId];
        uint256 totalPrice = safeMul(priceWei, quantity);
        require(msg.value == totalPrice, "incorrect eth");
        
        userPackBalance[msg.sender][packId] = safeAdd(userPackBalance[msg.sender][packId], quantity);
        emit PackPurchased(msg.sender, packId, quantity, totalPrice);
    }

    // ---------- NFT Minting from Pack ----------
    function mintFromPack(uint256 packId) external nonReentrant returns (uint256 tokenId) {
        require(packActive[packId], "pack inactive");
        
        uint256 creditCost = packCreditCost[packId];
        uint256 availablePacks = userPackBalance[msg.sender][packId];
        
        require(availablePacks >= 1, "no pack");
        require(creditsOf[msg.sender] >= creditCost, "insufficient credits");

        uint256 ethEquivalent = safeDiv(safeMul(creditCost, 1000000), creditsPerEth);
        require(stakedBalanceWei[msg.sender] >= ethEquivalent, "insufficient staked backing");

        // Spend resources
        userPackBalance[msg.sender][packId] = safeSub(availablePacks, 1);
        creditsOf[msg.sender] = safeSub(creditsOf[msg.sender], creditCost);

        // Shift backing ETH
        stakedBalanceWei[msg.sender] = safeSub(stakedBalanceWei[msg.sender], ethEquivalent);
        totalStakedWei = safeSub(totalStakedWei, ethEquivalent);
        ethEarnedFromSpentCreditsOfUser[msg.sender] = safeAdd(ethEarnedFromSpentCreditsOfUser[msg.sender], ethEquivalent);

        // Mint NFT
        tokenId = safeAdd(totalSupply, 1);
        totalSupply = tokenId;
        _mint(msg.sender, tokenId);

        emit MintedFromPack(msg.sender, packId, tokenId, creditCost);
    }

    // Allow contract to receive TRX
    function() external payable {}
}