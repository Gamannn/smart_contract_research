```solidity
pragma solidity ^0.4.18;

contract SafeMath {
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

contract EggGame {
    using SafeMath for uint256;
    
    uint256 public EGGS_TO_HATCH_1CAT = 86400;
    uint256 public STARTING_CAT = 300;
    uint256 public PSN = 10000;
    uint256 public PSNH = 5000;
    uint256 public devFeeVal = 4;
    
    bool public initialized = false;
    address public ceoAddress;
    uint256 public marketEggs;
    
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    
    constructor() public {
        ceoAddress = msg.sender;
    }
    
    function hatchEggs(address ref) public {
        require(initialized);
        
        if (ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = ceoAddress;
        }
        
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 eggsUsed = getMyEggs();
        uint256 newMiners = eggsUsed.div(EGGS_TO_HATCH_1CAT);
        hatcheryMiners[msg.sender] = hatcheryMiners[msg.sender].add(newMiners);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        claimedEggs[referrals[msg.sender]] = claimedEggs[referrals[msg.sender]].add(eggsUsed.div(5));
        marketEggs = marketEggs.add(eggsUsed.div(10));
    }
    
    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = marketEggs.add(hasEggs);
        ceoAddress.transfer(fee);
        msg.sender.transfer(eggValue.sub(fee));
    }
    
    function buyEggs() public payable {
        require(initialized);
        uint256 eggsBought = calculateEggBuy(msg.value, address(this).balance.sub(msg.value));
        eggsBought = eggsBought.sub(devFee(eggsBought));
        ceoAddress.transfer(devFee(msg.value));
        claimedEggs[msg.sender] = claimedEggs[msg.sender].add(eggsBought);
    }
    
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }
    
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs, marketEggs, address(this).balance);
    }
    
    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketEggs);
    }
    
    function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth, address(this).balance);
    }
    
    function devFee(uint256 amount) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, devFeeVal), 100);
    }
    
    function seedMarket(uint256 eggs) public payable {
        require(msg.sender == ceoAddress);
        require(marketEggs == 0);
        initialized = true;
        marketEggs = eggs;
    }
    
    function getFreeCat() public {
        require(initialized);
        require(hatcheryMiners[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        hatcheryMiners[msg.sender] = STARTING_CAT;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners() public view returns(uint256) {
        return hatcheryMiners[msg.sender];
    }
    
    function getMyEggs() public view returns(uint256) {
        return claimedEggs[msg.sender].add(getEggsSinceLastHatch(msg.sender));
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1CAT, now.sub(lastHatch[adr]));
        return secondsPassed.mul(hatcheryMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
```