```solidity
pragma solidity ^0.4.18;

contract ShrimpFarm {
    mapping(address => uint256) public shrimpBalance;
    mapping(address => uint256) public lastHatch;
    mapping(address => address) public referrals;
    uint256 public marketShrimp;
    address public ceoAddress;
    bool public initialized = false;
    uint256 public constant STARTING_SHRIMP = 300;
    uint256 public constant PSN = 10000;
    uint256 public constant PSNH = 5000;

    function ShrimpFarm() public {
        ceoAddress = msg.sender;
    }

    function hatchEggs(address ref) public {
        require(initialized);
        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newShrimp = SafeMath.div(eggsUsed, PSN);
        shrimpBalance[msg.sender] = SafeMath.add(shrimpBalance[msg.sender], newShrimp);
        lastHatch[msg.sender] = now;
        shrimpBalance[referrals[msg.sender]] = SafeMath.add(shrimpBalance[referrals[msg.sender]], SafeMath.div(SafeMath.mul(eggsUsed, 5), 100));
        marketShrimp = SafeMath.add(marketShrimp, SafeMath.div(eggsUsed, 10));
    }

    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        shrimpBalance[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketShrimp = SafeMath.add(marketShrimp, hasEggs);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue, fee));
    }

    function buyEggs() public payable {
        require(initialized);
        uint256 eggsBought = calculateEggBuy(msg.value, SafeMath.sub(this.balance, msg.value));
        eggsBought = SafeMath.sub(eggsBought, devFee(eggsBought));
        ceoAddress.transfer(devFee(msg.value));
        shrimpBalance[msg.sender] = SafeMath.add(shrimpBalance[msg.sender], eggsBought);
    }

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns (uint256) {
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

    function calculateEggSell(uint256 eggs) public view returns (uint256) {
        return calculateTrade(eggs, marketShrimp, this.balance);
    }

    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketShrimp);
    }

    function calculateEggBuySimple(uint256 eth) public view returns (uint256) {
        return calculateEggBuy(eth, this.balance);
    }

    function devFee(uint256 amount) public view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, 4), 100);
    }

    function seedMarket(uint256 eggs) public payable {
        require(marketShrimp == 0);
        initialized = true;
        marketShrimp = eggs;
    }

    function getFreeShrimp() public {
        require(initialized);
        require(shrimpBalance[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        shrimpBalance[msg.sender] = STARTING_SHRIMP;
    }

    function getBalance() public view returns (uint256) {
        return this.balance;
    }

    function getMyShrimp() public view returns (uint256) {
        return shrimpBalance[msg.sender];
    }

    function getMyEggs() public view returns (uint256) {
        return SafeMath.add(shrimpBalance[msg.sender], getEggsSinceLastHatch(msg.sender));
    }

    function getEggsSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(PSNH, SafeMath.sub(now, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, shrimpBalance[adr]);
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
```