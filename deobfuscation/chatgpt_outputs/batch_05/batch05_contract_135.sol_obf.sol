```solidity
pragma solidity ^0.4.20;

contract AlienEggs {
    uint256 public marketEggs;
    mapping(address => uint256) public hatcheryAliens;
    mapping(address => uint256) public claimedEggs;
    mapping(address => uint256) public lastHatch;
    mapping(address => address) public referrals;
    uint256 public eggsToHatch1Alien = 86400;
    address public ceoAddress;
    bool public initialized = false;
    uint256 public startingAlien = 300;
    uint256 public PSN = 10000;
    uint256 public PSNH = 5000;

    event onHatchEggs(address indexed user, uint256 eggsUsed, address indexed referrer);
    event onSellEggs(address indexed user, uint256 eggsSold, uint256 eggValue);
    event onBuyEggs(address indexed user, uint256 eggsBought, uint256 ethSpent);

    function AlienEggs() public {
        ceoAddress = msg.sender;
    }

    function hatchEggs(address ref) public {
        require(initialized);
        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newAliens = eggsUsed / eggsToHatch1Alien;
        hatcheryAliens[msg.sender] += newAliens;
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        claimedEggs[referrals[msg.sender]] += eggsUsed / 5;
        onHatchEggs(msg.sender, eggsUsed, ref);
    }

    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs += hasEggs;
        ceoAddress.transfer(fee);
        msg.sender.transfer(eggValue - fee);
        onSellEggs(msg.sender, hasEggs, eggValue);
    }

    function buyEggs() public payable {
        require(initialized);
        uint256 eggsBought = calculateEggBuy(msg.value, this.balance - msg.value);
        uint256 fee = devFee(msg.value);
        ceoAddress.transfer(fee);
        claimedEggs[msg.sender] += eggsBought;
        onBuyEggs(msg.sender, eggsBought, msg.value);
    }

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns (uint256) {
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

    function calculateEggSell(uint256 eggs) public view returns (uint256) {
        return calculateTrade(eggs, marketEggs, this.balance);
    }

    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    function calculateEggBuySimple(uint256 eth) public view returns (uint256) {
        return calculateEggBuy(eth, this.balance);
    }

    function devFee(uint256 amount) public pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, 4), 100);
    }

    function seedMarket(uint256 eggs) public {
        require(marketEggs == 0);
        initialized = true;
        marketEggs = eggs;
    }

    function getFreeAlien() public {
        require(initialized);
        require(hatcheryAliens[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        hatcheryAliens[msg.sender] = startingAlien;
    }

    function getBalance() public view returns (uint256) {
        return this.balance;
    }

    function getMyAliens() public view returns (uint256) {
        return hatcheryAliens[msg.sender];
    }

    function getMyEggs() public view returns (uint256) {
        return SafeMath.add(claimedEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
    }

    function getEggsSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(eggsToHatch1Alien, SafeMath.sub(now, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, hatcheryAliens[adr]);
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