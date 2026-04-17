pragma solidity ^0.4.18;

contract EggMarket {
    mapping(address => uint256) public eggBalance;
    mapping(address => uint256) public lastHatch;
    mapping(address => address) public referrals;
    uint256 public marketEggs;
    address public ceoAddress;
    bool public initialized = false;
    uint256 public constant EGGS_TO_HATCH_1CAT = 86400;
    uint256 public constant STARTING_CAT = 300;

    function EggMarket() public {
        ceoAddress = msg.sender;
    }

    function hatchEggs(address ref) public {
        require(initialized);
        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newCats = eggsUsed / EGGS_TO_HATCH_1CAT;
        eggBalance[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        eggBalance[referrals[msg.sender]] += SafeMath.div(SafeMath.mul(eggsUsed, 5), 100);
        marketEggs += SafeMath.div(SafeMath.mul(eggsUsed, 10), 100);
    }

    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        eggBalance[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs += hasEggs;
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue, fee));
    }

    function buyEggs() public payable {
        require(initialized);
        uint256 eggsBought = calculateEggBuy(msg.value, SafeMath.sub(this.balance, msg.value));
        eggsBought = SafeMath.sub(eggsBought, devFee(eggsBought));
        ceoAddress.transfer(devFee(msg.value));
        eggBalance[msg.sender] = SafeMath.add(eggBalance[msg.sender], eggsBought);
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

    function devFee(uint256 amount) public view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, 4), 100);
    }

    function seedMarket(uint256 eggs) public payable {
        require(marketEggs == 0);
        initialized = true;
        marketEggs = eggs;
    }

    function getFreeCat() public {
        require(initialized);
        require(eggBalance[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        eggBalance[msg.sender] = STARTING_CAT;
    }

    function getBalance() public view returns (uint256) {
        return this.balance;
    }

    function getMyCats() public view returns (uint256) {
        return eggBalance[msg.sender];
    }

    function getMyEggs() public view returns (uint256) {
        return SafeMath.add(eggBalance[msg.sender], getEggsSinceLastHatch(msg.sender));
    }

    function getEggsSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1CAT, SafeMath.sub(now, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, eggBalance[adr]);
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
        return a / b;
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