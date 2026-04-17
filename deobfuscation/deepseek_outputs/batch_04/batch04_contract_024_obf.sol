pragma solidity ^0.4.18;

contract Ox5b42965c993ee8a81d9815ca6efc5bf839dc03d8 {
    using SafeMath for uint256;
    
    uint256 constant PSN = 10000;
    uint256 constant PSNH = 5000;
    uint256 constant EGGS_TO_HATCH_1CHICKEN = 86400;
    uint256 constant STARTING_CHICKEN = 5000;
    
    bool public initialized = false;
    address public ceoAddress;
    address public ceoAddress2;
    
    mapping (address => uint256) public hatcheryChicken;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    
    uint256 public marketEggs;
    
    constructor() public {
        ceoAddress = msg.sender;
        ceoAddress2 = address(0x48baB4A535d4CF9aEd72c5Db74fB392ee38ea3e1);
    }
    
    function hatchEggs(address ref) public {
        require(initialized);
        
        if (ref == msg.sender || ref == address(0) || hatcheryChicken[ref] == 0) {
            ref = ceoAddress;
        }
        
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 eggsUsed = getMyEggs();
        uint256 newChicken = eggsUsed.div(EGGS_TO_HATCH_1CHICKEN);
        
        if (now.sub(lastHatch[msg.sender]) >= EGGS_TO_HATCH_1CHICKEN) {
            newChicken = newChicken.add(eggsUsed.mul(20).div(100));
        }
        
        hatcheryChicken[msg.sender] = hatcheryChicken[msg.sender].add(newChicken);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        claimedEggs[referrals[msg.sender]] = claimedEggs[referrals[msg.sender]].add(eggsUsed.mul(10).div(100));
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
        
        ceoAddress2.transfer(fee.div(2));
        ceoAddress.transfer(fee.div(2));
        msg.sender.transfer(eggValue.sub(fee));
    }
    
    function buyEggs(address ref) public payable {
        require(initialized);
        
        uint256 eggsBought = calculateEggBuy(msg.value, address(this).balance.sub(msg.value));
        eggsBought = eggsBought.sub(devFee(eggsBought));
        uint256 fee = devFee(msg.value);
        
        ceoAddress2.transfer(fee.div(2));
        ceoAddress.transfer(fee.div(2));
        
        claimedEggs[msg.sender] = claimedEggs[msg.sender].add(eggsBought);
        
        if (hatcheryChicken[msg.sender] == 0) {
            lastHatch[msg.sender] = now;
        }
        
        hatchEggs(ref);
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
        return amount.mul(2).div(100);
    }
    
    function seedMarket(uint256 eggs) public payable {
        require(marketEggs == 0);
        initialized = true;
        marketEggs = eggs;
    }
    
    function startFarming() public {
        require(initialized);
        require(hatcheryChicken[msg.sender] == 0);
        
        lastHatch[msg.sender] = now;
        hatcheryChicken[msg.sender] = STARTING_CHICKEN;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyChicken() public view returns(uint256) {
        return hatcheryChicken[msg.sender];
    }
    
    function getMyEggs() public view returns(uint256) {
        return claimedEggs[msg.sender].add(chickenSinceLastHatch(msg.sender));
    }
    
    function chickenSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1CHICKEN, now.sub(lastHatch[adr]));
        return secondsPassed.mul(hatcheryChicken[adr]);
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