```solidity
pragma solidity ^0.4.18;

contract ShrimpFarmer {
    using SafeMath for uint256;
    
    uint256 public EGGS_TO_HATCH_1SHRIMP = 86400;
    uint256 public PSN = 10000;
    uint256 public PSNH = 5000;
    uint256 public devFeeVal = 4;
    uint256 public marketEggs = 200000000000000000;
    
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    mapping (address => bool) public hasInitialized;
    
    uint256 public marketEggsTotal;
    address public ceoAddress;
    address public goldOwner;
    bool public initialized = false;
    
    constructor() public {
        ceoAddress = msg.sender;
    }
    
    function buyEggs(address ref) public payable {
        require(initialized);
        require(msg.value >= getCurrentEggPrice());
        
        uint256 excess = 0;
        uint256 amount = msg.value;
        
        if (msg.value > getCurrentEggPrice()) {
            excess = msg.value - getCurrentEggPrice();
            amount = getCurrentEggPrice();
        } else {
            amount = msg.value;
        }
        
        uint256 eggsBought = calculateEggBuy(amount, SafeMath.sub(address(this).balance, amount));
        eggsBought = SafeMath.sub(eggsBought, devFee(eggsBought));
        
        uint256 fee = devFee(amount);
        ceoAddress.transfer(fee);
        
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender], eggsBought);
        
        if (ref == address(0) || ref == msg.sender) {
            ref = ceoAddress;
        }
        
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = ref;
        }
        
        hatchEggs(ref);
        
        if (excess > 0) {
            msg.sender.transfer(excess);
        }
    }
    
    function hatchEggs(address ref) public {
        require(initialized);
        require(ref != address(0));
        require(ref != msg.sender);
        
        uint256 eggsUsed = getMyEggs();
        uint256 newShrimp = SafeMath.div(eggsUsed, EGGS_TO_HATCH_1SHRIMP);
        hatcheryShrimp[msg.sender] = SafeMath.add(hatcheryShrimp[msg.sender], newShrimp);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        claimedEggs[referrals[msg.sender]] = SafeMath.add(claimedEggs[referrals[msg.sender]], SafeMath.div(eggsUsed, 10));
        marketEggsTotal = SafeMath.add(marketEggsTotal, SafeMath.div(eggsUsed, 10));
    }
    
    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggsTotal = SafeMath.add(marketEggsTotal, hasEggs);
        
        hatcheryShrimp[msg.sender] = SafeMath.mul(SafeMath.div(hatcheryShrimp[msg.sender], 3), 4);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue, fee));
    }
    
    function buyGold() public payable {
        require(initialized);
        require(msg.value >= getCurrentGoldPrice());
        require(msg.sender != goldOwner);
        
        uint256 excess = 0;
        uint256 amount = msg.value;
        
        if (msg.value > getCurrentGoldPrice()) {
            excess = msg.value - getCurrentGoldPrice();
            amount = getCurrentGoldPrice();
        } else {
            amount = msg.value;
        }
        
        amount = SafeMath.sub(amount, devFee(amount));
        uint256 eggsBought = calculateEggBuy(amount, SafeMath.sub(address(this).balance, amount));
        
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender], eggsBought);
        lastHatch[msg.sender] = now;
        
        eggsBought = getEggsSinceLastHatch(goldOwner);
        claimedEggs[goldOwner] = SafeMath.add(claimedEggs[goldOwner], eggsBought);
        lastHatch[goldOwner] = now;
        
        uint256 newPrice = SafeMath.div(SafeMath.mul(getCurrentGoldPrice(), 100 + getCurrentGoldPercentIncrease()), 100);
        
        address oldOwner = goldOwner;
        goldOwner = msg.sender;
        
        ceoAddress.transfer(devFee(amount));
        
        if (excess > 0) {
            msg.sender.transfer(excess);
        }
    }
    
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }
    
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs, marketEggsTotal, address(this).balance);
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
        require(!initialized);
        initialized = true;
        marketEggsTotal = eggs;
    }
    
    function initializeAccount() public {
        require(initialized);
        require(hatcheryShrimp[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        hatcheryShrimp[msg.sender] = EGGS_TO_HATCH_1SHRIMP;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyShrimp() public view returns(uint256) {
        return hatcheryShrimp[msg.sender];
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1SHRIMP, SafeMath.sub(now, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, hatcheryShrimp[adr]);
    }
    
    function getMyEggs() public view returns(uint256) {
        uint256 eggs = SafeMath.add(claimedEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
        
        if (hasInitialized[msg.sender]) {
            eggs = SafeMath.div(eggs, 2);
        }
        
        if (msg.sender == goldOwner) {
            eggs = SafeMath.div(eggs, 4);
        }
        
        return eggs;
    }
    
    function getCurrentEggPrice() public view returns(uint256) {
        return calculateEggBuy(EGGS_TO_HATCH_1SHRIMP, SafeMath.sub(address(this).balance, EGGS_TO_HATCH_1SHRIMP));
    }
    
    function getCurrentGoldPrice() public view returns(uint256) {
        return 10000000000000000;
    }
    
    function getCurrentGoldPercentIncrease() public view returns(uint256) {
        return 7;
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