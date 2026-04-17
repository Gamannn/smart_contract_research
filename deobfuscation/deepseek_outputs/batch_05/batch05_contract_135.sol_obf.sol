```solidity
pragma solidity ^0.4.20;

contract AlienFarm {
    using SafeMath for uint256;
    
    uint256 public EGGS_TO_HATCH_1ALIEN = 86400;
    uint256 public STARTING_ALIEN = 5000;
    uint256 public PSN = 10000;
    uint256 public PSNH = 10;
    uint256 public marketEggs;
    address public ceoAddress;
    bool public initialized = false;
    
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    
    event onHatchEggs(
        address indexed customer,
        uint256 eggs,
        address indexed referredBy
    );
    
    event onSellEggs(
        address indexed customer,
        uint256 eggs,
        uint256 amount
    );
    
    event onBuyEggs(
        address indexed customer,
        uint256 eggs,
        uint256 amount
    );
    
    constructor() public {
        ceoAddress = 0x4B4f724B936290bDADC87439856Eaf2671eb5072;
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
        uint256 newMiners = SafeMath.div(eggsUsed, EGGS_TO_HATCH_1ALIEN);
        hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender], newMiners);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        claimedEggs[referrals[msg.sender]] = SafeMath.add(
            claimedEggs[referrals[msg.sender]],
            SafeMath.div(eggsUsed, 5)
        );
        
        marketEggs = SafeMath.add(marketEggs, SafeMath.div(eggsUsed, 10));
        
        emit onHatchEggs(msg.sender, newMiners, ref);
    }
    
    function sellEggs() public {
        require(initialized);
        
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = SafeMath.add(marketEggs, hasEggs);
        
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue, fee));
        
        emit onSellEggs(msg.sender, hasEggs, SafeMath.sub(eggValue, fee));
    }
    
    function buyEggs() public payable {
        require(initialized);
        
        uint256 eggsBought = calculateEggBuy(
            msg.value,
            SafeMath.sub(address(this).balance, msg.value)
        );
        
        uint256 fee = devFee(msg.value);
        
        eggsBought = SafeMath.sub(eggsBought, devFee(eggsBought));
        
        ceoAddress.transfer(fee);
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender], eggsBought);
        
        emit onBuyEggs(msg.sender, eggsBought, msg.value);
    }
    
    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) public view returns(uint256) {
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
        return SafeMath.div(SafeMath.mul(amount, 4), 100);
    }
    
    function seedMarket(uint256 eggs) public payable {
        require(msg.sender == ceoAddress);
        require(marketEggs == 0);
        
        initialized = true;
        marketEggs = eggs;
    }
    
    function setFee(uint256 newFee) public {
        require(msg.sender == ceoAddress);
        require(newFee >= 10);
        PSNH = newFee;
    }
    
    function getFreeAlien() public {
        require(initialized);
        require(hatcheryMiners[msg.sender] == 0);
        
        lastHatch[msg.sender] = now;
        hatcheryMiners[msg.sender] = STARTING_ALIEN;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners() public view returns(uint256) {
        return hatcheryMiners[msg.sender];
    }
    
    function getMyEggs() public view returns(uint256) {
        return SafeMath.add(claimedEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1ALIEN, SafeMath.sub(now, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, hatcheryMiners[adr]);
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