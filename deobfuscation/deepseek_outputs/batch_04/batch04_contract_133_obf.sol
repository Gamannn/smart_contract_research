```solidity
pragma solidity ^0.4.26;

contract ShrimpFarmer {
    using SafeMath for uint256;
    
    uint256 public EGGS_TO_HATCH_1SHRIMP = 86400;
    uint256 public STARTING_SHRIMP = 5000;
    uint256 public PSN = 10000;
    uint256 public PSNH = 5000;
    uint256 public marketEggs;
    bool public initialized = false;
    address public ceoAddress;
    
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    
    constructor() public {
        ceoAddress = msg.sender;
    }
    
    function hatchEggs(address ref) public {
        require(initialized);
        
        if (ref == msg.sender || ref == address(0) || hatcheryShrimp[ref] == 0) {
            ref = ceoAddress;
        }
        
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = ref;
        }
        
        uint256 eggsUsed = getMyEggs();
        uint256 newShrimp = eggsUsed.div(EGGS_TO_HATCH_1SHRIMP);
        hatcheryShrimp[msg.sender] = hatcheryShrimp[msg.sender].add(newShrimp);
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
        return SafeMath.div(
            SafeMath.mul(PSN, bs), 
            SafeMath.add(
                PSNH, 
                SafeMath.div(
                    SafeMath.add(
                        SafeMath.mul(PSN, rs), 
                        SafeMath.mul(PSNH, rt)
                    ), 
                    rt
                )
            )
        );
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
    
    function devFee(uint256 amount) public pure returns(uint256) {
        return amount.mul(5).div(100);
    }
    
    function seedMarket(uint256 eggs) public payable {
        require(marketEggs == 0);
        initialized = true;
        marketEggs = eggs;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyShrimp() public view returns(uint256) {
        return hatcheryShrimp[msg.sender];
    }
    
    function getMyEggs() public view returns(uint256) {
        return claimedEggs[msg.sender].add(getEggsSinceLastHatch(msg.sender));
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1SHRIMP, now.sub(lastHatch[adr]));
        return secondsPassed.mul(hatcheryShrimp[adr]);
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