pragma solidity ^0.4.19;

contract ShrimpFarmer {
    uint256 public EGGS_TO_HATCH_1SHRIMP = 86400;
    uint256 public marketEggs;
    address public ceoAddress;
    bool public initialized = false;
    mapping(address => uint256) public hatcheryShrimp;
    mapping(address => uint256) public claimedEggs;
    mapping(address => uint256) public lastHatch;
    mapping(address => address) public referrals;

    function ShrimpFarmer() public {
        ceoAddress = msg.sender;
    }

    function hatchEggs(address ref) public {
        require(initialized);
        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newShrimp = eggsUsed / EGGS_TO_HATCH_1SHRIMP;
        hatcheryShrimp[msg.sender] += newShrimp;
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        claimedEggs[referrals[msg.sender]] += eggsUsed / 5;
        marketEggs += eggsUsed / 10;
    }

    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs += hasEggs;
        ceoAddress.transfer(eggValue);
    }

    function buyEggs() public payable {
        require(initialized);
        uint256 eggsBought = calculateEggBuy(msg.value, this.balance - msg.value);
        eggsBought -= devFee(eggsBought);
        ceoAddress.transfer(devFee(msg.value));
        claimedEggs[msg.sender] += eggsBought;
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

    function seedMarket(uint256 eggs) public payable {
        require(marketEggs == 0);
        initialized = true;
        marketEggs = eggs;
    }

    function getFreeShrimp() public payable {
        require(initialized);
        require(msg.value == 0.001 ether);
        ceoAddress.transfer(msg.value);
        hatcheryShrimp[msg.sender] = SafeMath.div(1, EGGS_TO_HATCH_1SHRIMP);
    }

    function getBalance() public view returns (uint256) {
        return this.balance;
    }

    function getMyShrimp() public view returns (uint256) {
        return hatcheryShrimp[msg.sender];
    }

    function getMyEggs() public view returns (uint256) {
        return SafeMath.add(claimedEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
    }

    function getEggsSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1SHRIMP, SafeMath.sub(now, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, hatcheryShrimp[adr]);
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