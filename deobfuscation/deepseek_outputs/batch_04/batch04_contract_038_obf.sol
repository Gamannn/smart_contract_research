```solidity
pragma solidity ^0.4.23;

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }
    
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

interface ICore {
    function isValid() pure external returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getAuction(uint256 auctionId) external view returns (
        uint256 tokenId,
        uint40 startTime,
        uint40 endTime,
        uint40 duration,
        uint40 extensionDuration,
        uint16 sellerFee,
        uint16 buyerFee
    );
    function getAuctionTokenId(uint256 auctionId) public view returns (uint256 tokenId);
    function getAuctionEndTime(uint256 auctionId) public view returns (uint40 endTime);
    function getAuctionSellerFee(uint256 auctionId) public view returns (uint16 sellerFee);
    function getAuctionBuyerFee(uint256 auctionId) public view returns (uint16 buyerFee);
    function getAuctionCurrentPrice(uint256 auctionId) public view returns (uint128 currentPrice);
    function setAuctionPrice(uint256 auctionId, uint256 price) public;
    function setAuctionEndTime(uint256 auctionId, uint40 endTime) public;
    function setAuctionSellerFee(uint256 auctionId, uint16 sellerFee) public;
    function setAuctionCurrentPrice(uint256 auctionId, uint128 currentPrice) public;
    function setAuctionBuyerFee(uint256 auctionId, uint16 buyerFee) public;
    function createAuction(
        uint256 tokenId,
        uint128 startPrice,
        uint128 endPrice,
        uint40 duration
    ) public;
    function cancelAuction(uint256 auctionId) external returns (address seller);
    function totalAuctions() view external returns (uint256);
    function createAuctionFor(
        uint256 tokenId,
        address seller,
        uint128 startPrice,
        uint128 endPrice,
        uint40 duration
    ) external;
    function createAuctionForWithRoyalties(
        uint256 tokenId,
        address seller,
        uint128 startPrice,
        uint128 endPrice,
        uint40 duration,
        address[] calldata royaltyRecipients
    ) external;
    function bid(uint256 auctionId, address bidder, uint16 buyerFee) external;
    function bidMultiple(uint256[] calldata auctionIds, address bidder, uint16 buyerFee) external;
}

contract Operators {
    mapping(address => bool) public owners;
    mapping(address => bool) public operators;
    
    constructor() public {
        owners[msg.sender] = true;
    }
    
    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }
    
    function isOwner(address account) public view returns (bool) {
        return owners[account];
    }
    
    function addOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owners[newOwner] = true;
    }
    
    function removeOwner(address oldOwner) external onlyOwner {
        delete owners[oldOwner];
    }
    
    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }
    
    function isOperator(address account) public view returns (bool) {
        return operators[account] || owners[account];
    }
    
    function addOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0));
        operators[newOperator] = true;
    }
    
    function removeOperator(address oldOperator) external onlyOwner {
        delete operators[oldOperator];
    }
}

contract PausableOperators is Operators {
    event Pause();
    event Unpause();
    
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }
    
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract BaseAuction is IERC20, PausableOperators {
    function transfer(address to, uint256 value) external returns (bool) {
        return true;
    }
    
    function balanceOf(address who) external view returns (uint256) {
        return 0;
    }
    
    ICore public coreContract;
    address public feeRecipient;
    
    modifier onlyCore() {
        require(msg.sender == address(coreContract));
        _;
    }
    
    modifier onlyOperatorOrCore() {
        require(isOperator(msg.sender) || msg.sender == address(coreContract));
        _;
    }
    
    function initialize(address coreAddress, address recipient) public onlyOwner {
        ICore core = ICore(coreAddress);
        require(core.isValid());
        coreContract = core;
        feeRecipient = recipient;
    }
    
    function isTokenOwner(address owner, uint256 tokenId) internal view returns (bool) {
        return (coreContract.ownerOf(tokenId) == owner);
    }
    
    function transferToken(address to, uint256 tokenId) internal {
        coreContract.transferFrom(to, this, tokenId);
    }
    
    function approveToken(address from, uint256 tokenId) internal {
        coreContract.approve(from, tokenId);
    }
    
    function withdraw() external {
        require(
            isOwner(msg.sender) || msg.sender == address(coreContract)
        );
        withdrawBalance();
    }
    
    function withdrawBalance() internal {
        if (address(this).balance > 0) {
            coreContract.approve(address(this).balance);
        }
    }
    
    function withdrawETH() public onlyOperatorOrCore {
        withdrawBalance();
    }
    
    function onERC721Received(uint256, uint256, address) public payable onlyCore returns (bytes4) {
        revert();
    }
    
    function onERC721Received(address, uint256, bytes calldata) external payable onlyCore returns (bytes4) {
        revert();
    }
}

contract FeeAuction is BaseAuction {
    uint16 public feePercentage;
    
    constructor(uint16 initialFee, address coreAddress, address recipient) public {
        feePercentage = initialFee;
        super.initialize(coreAddress, recipient);
    }
    
    function setFeePercentage(uint16 newFee) external onlyOwner {
        require(newFee <= 10000);
        feePercentage = newFee;
    }
    
    function calculateFee(uint128 amount) internal view returns (uint128) {
        return amount * feePercentage / 10000;
    }
}

contract EnglishAuction is FeeAuction {
    event Transfer(address from, address to, uint128 amount);
    
    function onERC721Received(uint256, uint256, address) public payable onlyOperatorOrCore returns (bytes4) {
        revert();
    }
    
    function onERC721Received(address, uint256 tokenId, bytes calldata) external payable onlyOperatorOrCore returns (bytes4) {
        uint40 endTime = uint40(tokenId / 0x0010000000000000000000000000000000000000000);
        require(now <= endTime);
        
        uint256 feeAmount = 96 * msg.value / 100;
        address(feeRecipient).transfer(feeAmount);
    }
}
```