```solidity
pragma solidity ^0.4.24;

contract Norsefire {
    using SafeMath for uint256;
    
    event MarketBoost(uint256 boostAmount);
    event NorsefireSwitch(address indexed from, address indexed to, uint256 price);
    event ClonesDeployed(address indexed user, uint256 clones);
    event IdeasSold(address indexed user, uint256 ideas);
    event IdeasBought(address indexed user, uint256 ideas);
    
    uint256 public clones_to_create_one_idea = 2;
    uint256 public initialClonePrice = 0.00232 ether;
    uint256 public currentNorsefirePrice;
    uint256 public marketIdeas;
    uint256 public PSN = 10000;
    uint256 public PSNH = 5000;
    uint256 public clonesCreationRate = 172800;
    
    bool public initialized = false;
    address public ceoAddress;
    address public devAddress;
    
    mapping (address => uint256) public arrayOfClones;
    mapping (address => uint256) public claimedIdeas;
    mapping (address => uint256) public lastDeploy;
    mapping (address => address) public referrals;
    
    constructor() public {
        ceoAddress = msg.sender;
        devAddress = 0x1337eaD98EaDcE2E04B1cfBf57E111479854D29A;
        currentNorsefirePrice = 0.00232 ether;
    }
    
    function boostCloneMarket(uint256 _amount) public payable {
        require(initialized);
        require(msg.sender == ceoAddress);
        marketIdeas = marketIdeas.add(_amount);
    }
    
    function buyNorsefire(address _referrer) public payable {
        require(initialized);
        require(msg.value >= currentNorsefirePrice);
        
        uint256 oldNorsePrice = currentNorsefirePrice;
        uint256 excess = msg.value.sub(oldNorsePrice);
        currentNorsefirePrice = oldNorsePrice.mul(10).div(9);
        
        uint256 tax = oldNorsePrice.mul(9).div(10);
        uint256 devFee = tax.div(10);
        uint256 marketBoost = tax.div(9);
        
        address newNorseOwner = msg.sender;
        uint256 prize = (oldNorsePrice.sub(initialClonePrice)).mul(PSN).div(PSNH);
        
        ceoAddress = newNorseOwner;
        payable(ceoAddress).transfer(prize);
        payable(devAddress).transfer(devFee);
        
        boostCloneMarket(marketBoost);
        emit NorsefireSwitch(ceoAddress, newNorseOwner, currentNorsefirePrice);
    }
    
    function deployClones(address _referrer) public {
        require(initialized);
        
        address user = msg.sender;
        if(referrals[user] == address(0) && referrals[user] != user) {
            referrals[user] = _referrer;
        }
        
        uint256 ideasUsed = getMyIdeas();
        uint256 newClones = ideasUsed.div(clones_to_create_one_idea);
        arrayOfClones[user] = arrayOfClones[user].add(newClones);
        claimedIdeas[user] = 0;
        lastDeploy[user] = now;
        
        if(referrals[user] != address(0) && arrayOfClones[referrals[user]] > 0) {
            claimedIdeas[referrals[user]] = claimedIdeas[referrals[user]].add(ideasUsed.div(20));
        }
        
        marketIdeas = marketIdeas.add(ideasUsed.div(10));
        emit ClonesDeployed(user, newClones);
    }
    
    function sellIdeas() public {
        require(initialized);
        
        address user = msg.sender;
        uint256 hasIdeas = getMyIdeas();
        uint256 ideaValue = calculateIdeaSell(hasIdeas);
        uint256 fee = devFee(ideaValue);
        
        claimedIdeas[user] = 0;
        lastDeploy[user] = now;
        marketIdeas = marketIdeas.add(hasIdeas);
        
        payable(ceoAddress).transfer(fee);
        payable(devAddress).transfer(ideaValue.sub(fee));
        emit IdeasSold(user, hasIdeas);
    }
    
    function buyIdeas() public payable {
        require(initialized);
        
        address user = msg.sender;
        uint256 amount = msg.value;
        uint256 ideasBought = calculateIdeaBuy(amount, address(this).balance.sub(amount));
        ideasBought = ideasBought.sub(devFee(ideasBought));
        
        payable(ceoAddress).transfer(devFee(amount));
        claimedIdeas[user] = claimedIdeas[user].add(ideasBought);
        emit IdeasBought(user, ideasBought);
    }
    
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        return PSN.mul(bs).div(PSNH.add(PSN.mul(rs).add(PSNH.mul(rt)).div(rt)));
    }
    
    function calculateIdeaSell(uint256 ideas) public view returns(uint256) {
        return calculateTrade(ideas, marketIdeas, address(this).balance);
    }
    
    function calculateIdeaBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketIdeas);
    }
    
    function calculateIdeaBuySimple(uint256 eth) public view returns(uint256) {
        return calculateIdeaBuy(eth, address(this).balance);
    }
    
    function devFee(uint256 amount) public pure returns(uint256) {
        return amount.mul(4).div(100);
    }
    
    function seedMarket(uint256 _ideas) public payable {
        require(msg.sender == ceoAddress);
        require(marketIdeas == 0);
        initialized = true;
        marketIdeas = _ideas;
        boostCloneMarket(msg.value);
    }
    
    function getFreeClones() public payable {
        require(initialized);
        require(msg.value == 0.00232 ether);
        
        address user = msg.sender;
        payable(ceoAddress).transfer(msg.value);
        lastDeploy[user] = now;
        arrayOfClones[user] = initialClonePrice;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyClones() public view returns(uint256) {
        return arrayOfClones[msg.sender];
    }
    
    function getNorsefirePrice() public view returns(uint256) {
        return currentNorsefirePrice;
    }
    
    function getMyIdeas() public view returns(uint256) {
        address user = msg.sender;
        return claimedIdeas[user].add(getIdeasSinceLastDeploy(user));
    }
    
    function getIdeasSinceLastDeploy(address user) public view returns(uint256) {
        uint256 secondsPassed = min(clonesCreationRate, now.sub(lastDeploy[user]));
        return secondsPassed.mul(arrayOfClones[user]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
```