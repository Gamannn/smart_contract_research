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
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ICore {
    function isCore() external pure returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getKitty(uint256 id) external view returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    );
    function getKittyBasic(uint256 id) external view returns (bool isGestating, bool isReady, uint256 cooldownIndex, uint256 nextActionAt);
    function getKittySiring(uint256 id) external view returns (uint256 siringWithId);
    function getKittyBirth(uint256 id) external view returns (uint256 birthTime);
    function getKittyParents(uint256 id) external view returns (uint256 matronId, uint256 sireId);
    function getKittyGeneration(uint256 id) external view returns (uint256 generation);
    function getKittyGenes(uint256 id) external view returns (uint256 genes);
    function setSiringAuctionAddress(address address) external;
    function setSaleAuctionAddress(address address) external;
    function createSaleAuction(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration) external;
    function createSiringAuction(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration) external;
    function bidOnSiringAuction(uint256 tokenId, uint256 bidAmount) external payable;
    function withdrawAuctionBalances() external;
    function pregnantKitties() external view returns (uint256);
    function approveSiring(address to, uint256 tokenId) external;
    function breedWithAuto(uint256 matronId, uint256 sireId) external payable returns (uint256);
    function giveBirth(uint256 matronId) external returns (uint256);
    function setGeneScienceAddress(address address) external;
    function setAutoBirthAddress(address address) external;
    function setCEO(address newCEO) external;
    function setCOO(address newCOO) external;
    function setCFO(address newCFO) external;
    function createPromoKitty(uint256 genes, address owner) external;
    function createGen0Auction(uint256 genes) external;
    function setKittyCooldown(uint256 tokenId, uint64 cooldownEndBlock) external;
    function setPregnant(uint256 tokenId) external;
    function setKittyBirthTime(uint256 tokenId, uint256 birthTime) external;
    function setKittySiringWithId(uint256 tokenId, uint256 siringWithId) external;
    function setKittyMatronId(uint256 tokenId, uint256 matronId) external;
    function setKittySireId(uint256 tokenId, uint256 sireId) external;
    function setKittyGeneration(uint256 tokenId, uint256 generation) external;
    function setKittyGenes(uint256 tokenId, uint256 genes) external;
    function transfer(address to, uint256 value) external returns (bool);
    function totalEtherBalance() external view returns (uint256);
    function withdrawBalance(uint256 amount, address to) external;
    function canBreedWith(uint256 matronId, uint256 sireId) external view returns (bool);
    function isPregnant(uint256 tokenId) external view returns (bool);
    function breedWith(uint256 matronId, uint256 sireId) external payable returns (uint256);
    function approve(address to, uint256 tokenId) external;
    function setSaleAuction(address newSaleAuction) external;
    function setSiringAuction(address newSiringAuction) external;
    function createSaleAuctionWithReferral(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration, address[] referrers) external;
    function bidOnSiringAuctionWithReferral(uint256 tokenId, address referrer, uint256 referralCut) external payable;
    function batchBidOnSiringAuction(uint256[] tokenIds, address referrer, uint256 referralCut) external payable;
}

contract Operatorable {
    mapping(address => bool) private operators;
    mapping(address => bool) private authorizedContracts;
    
    constructor() public {
        operators[msg.sender] = true;
    }
    
    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }
    
    function isOperator(address addr) public view returns (bool) {
        return operators[addr];
    }
    
    function addOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0));
        operators[newOperator] = true;
    }
    
    function removeOperator(address operator) external onlyOperator {
        delete operators[operator];
    }
    
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender));
        _;
    }
    
    function isAuthorized(address addr) public view returns (bool) {
        return authorizedContracts[addr] || operators[addr];
    }
    
    function addAuthorizedContract(address contractAddress) external onlyOperator {
        require(contractAddress != address(0));
        authorizedContracts[contractAddress] = true;
    }
    
    function removeAuthorizedContract(address contractAddress) external onlyOperator {
        delete authorizedContracts[contractAddress];
    }
}

contract PausableOperators is Operatorable {
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
    
    function pause() public onlyOperator whenNotPaused {
        paused = true;
        emit Pause();
    }
    
    function unpause() public onlyOperator whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract PluginBase is IERC20, PausableOperators {
    function transfer(address to, uint256 value) external returns (bool) {
        return true;
    }
    
    ICore public coreContract;
    address public pluginsContract;
    
    modifier onlyCore() {
        require(msg.sender == address(coreContract));
        _;
    }
    
    modifier onlyPlugins() {
        require(msg.sender == pluginsContract);
        _;
    }
    
    function setCore(address coreAddress, address pluginsAddress) public onlyOperator {
        ICore core = ICore(coreAddress);
        require(core.isCore());
        coreContract = core;
        pluginsContract = pluginsAddress;
    }
    
    function isOwner(address owner, uint256 tokenId) internal view returns (bool) {
        return (coreContract.ownerOf(tokenId) == owner);
    }
    
    function transferFromCore(address to, uint256 tokenId) internal {
        coreContract.transferFrom(to, this, tokenId);
    }
    
    function approveFromCore(address spender, uint256 tokenId) internal {
        coreContract.approve(spender, tokenId);
    }
    
    function withdraw() external {
        require(
            isOperator(msg.sender) || msg.sender == address(coreContract)
        );
        withdrawBalance();
    }
    
    function withdrawBalance() internal {
        if (address(this).balance > 0) {
            coreContract.transfer(address(this).balance);
        }
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        withdrawBalance();
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        revert();
    }
    
    function totalSupply() external view returns (uint256) {
        revert();
    }
    
    function balanceOf(address who) external view returns (uint256) {
        revert();
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        revert();
    }
}

contract PluginImpl is PluginBase {
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        revert();
    }
    
    function totalSupply() external view returns (uint256) {
        revert();
    }
    
    function balanceOf(address who) external view returns (uint256) {
        revert();
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        revert();
    }
}
```