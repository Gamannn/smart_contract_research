pragma solidity ^0.4.24;

contract Ox45feb3fdeccb98f42e106fcd0ae40da76f4a3a7a {
    using SafeMath for uint256;
    
    event MarketBoost(uint256 boostAmount);
    event NorsefireSwitch(address indexed from, address indexed to, uint256 amount);
    
    uint256 public clones_to_create;
    uint256 public start;
    
    mapping (address => uint256) public ideas;
    mapping (address => uint256) public PSN;
    mapping (address => uint256) public PSNH;
    mapping (address => address) public referrals;
    
    address public ceoAddress;
    bool public initialized = false;
    uint256 public marketIdeas;
    uint256 public PSNBought;
    uint256 public PSNHSupply;
    uint256 public minBuy = 0.1 ether;
    address public actualNorsefire = 0x1337a4aEfd5ec486E6e97b1d0aE055FAC8D879dE;
    uint256 public constant PSN_COST = 10000;
    uint256 public constant PSNH_COST = 5000;
    uint256 public constant IDEAS_PER_PSN = 100000000000000000;
    uint256 public constant TIME_TO_CREATE_1_IDEA = 172800;
    
    constructor() public {
        ceoAddress = msg.sender;
        initialized = false;
        minBuy = 0.1 ether;
        marketIdeas = IDEAS_PER_PSN * 100;
    }
    
    function buyIdeas(address ref) public payable {
        require(initialized);
        require(msg.value >= minBuy);
        
        uint256 ideasBought = calculateIdeasBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        ideasBought = ideasBought.sub(ideasBought.div(10));
        
        PSNBought = PSNBought.add(ideasBought.div(IDEAS_PER_PSN));
        ideas[msg.sender] = ideas[msg.sender].add(ideasBought);
        
        distributeIdeas(ref);
        
        marketIdeas = marketIdeas.add(ideasBought.div(10));
        
        ceoAddress.transfer(msg.value.div(10));
        actualNorsefire.transfer(msg.value.div(20));
        
        emit NorsefireSwitch(actualNorsefire, msg.sender, msg.value);
    }
    
    function distributeIdeas(address ref) internal {
        if (ref == msg.sender || ref == address(0) || ideas[ref] == 0) {
            ref = ceoAddress;
        }
        
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = ref;
        }
        
        uint256 ideasUsed = getMyIdeas();
        uint256 newIdeas = ideasUsed.div(IDEAS_PER_PSN);
        PSNH[msg.sender] = PSNH[msg.sender].add(newIdeas);
        ideas[msg.sender] = ideas[msg.sender].sub(ideasUsed);
        PSN[msg.sender] = PSN[msg.sender].add(newIdeas.mul(PSN_COST));
        
        PSN[referrals[msg.sender]] = PSN[referrals[msg.sender]].add(newIdeas.mul(PSNH_COST));
        PSNHSupply = PSNHSupply.add(newIdeas.mul(PSNH_COST));
        marketIdeas = marketIdeas.add(ideasUsed.div(5));
    }
    
    function sellIdeas() public {
        require(initialized);
        address user = msg.sender;
        uint256 hasIdeas = getMyIdeas();
        uint256 ideaValue = calculateIdeasSell(hasIdeas);
        uint256 fee = devFee(ideaValue);
        
        ideas[user] = ideas[user].sub(hasIdeas);
        PSN[user] = PSN[user].add(hasIdeas.div(IDEAS_PER_PSN));
        PSNH[user] = 0;
        
        marketIdeas = marketIdeas.add(hasIdeas);
        
        ceoAddress.transfer(fee);
        user.transfer(SafeMath.sub(ideaValue, fee));
    }
    
    function buyPSN() public payable {
        require(initialized);
        require(msg.value == 0.00232 ether);
        
        address user = msg.sender;
        ceoAddress.transfer(msg.value);
        
        require(ideas[user] == 0);
        PSNH[user] = now;
        ideas[user] = IDEAS_PER_PSN;
    }
    
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(
            SafeMath.mul(PSN_COST, bs), 
            SafeMath.add(
                PSNH_COST, 
                SafeMath.div(
                    SafeMath.add(
                        SafeMath.mul(PSN_COST, rs), 
                        SafeMath.mul(PSNH_COST, rt)
                    ), 
                    rt
                )
            )
        );
    }
    
    function calculateIdeasSell(uint256 ideasAmount) public view returns(uint256) {
        return calculateTrade(ideasAmount, marketIdeas, address(this).balance);
    }
    
    function calculateIdeasBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketIdeas);
    }
    
    function calculateIdeasBuySimple(uint256 eth) public view returns(uint256) {
        return calculateIdeasBuy(eth, address(this).balance);
    }
    
    function devFee(uint256 amount) public pure returns(uint256) {
        return amount.mul(4).div(100);
    }
    
    function seedMarket(uint256 seedAmount) public payable {
        require(msg.sender == ceoAddress);
        require(marketIdeas == 0);
        initialized = true;
        marketIdeas = seedAmount;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyIdeas() public view returns(uint256) {
        return ideas[msg.sender];
    }
    
    function getMinBuy() public view returns(uint256) {
        return minBuy;
    }
    
    function getMyPSN() public view returns(uint256) {
        address user = msg.sender;
        return PSN[user].add(getIdeasSinceLastHatch(user));
    }
    
    function getIdeasSinceLastHatch(address user) public view returns(uint256) {
        uint256 secondsPassed = min(TIME_TO_CREATE_1_IDEA, SafeMath.sub(now, PSNH[user]));
        return secondsPassed.mul(ideas[user]);
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