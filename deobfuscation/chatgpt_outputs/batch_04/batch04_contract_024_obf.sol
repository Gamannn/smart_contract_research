```solidity
pragma solidity ^0.4.18;

contract ChickenFarm {
    using SafeMath for uint256;

    uint256 public EGGS_TO_HATCH_1CHICKEN = 86400;
    uint256 public STARTING_CHICKEN = 100;
    uint256 public PSN = 10000;
    uint256 public PSNH = 5000;
    bool public initialized = false;
    address public ceoAddress;
    mapping(address => uint256) public hatcheryChicken;
    mapping(address => uint256) public claimedEggs;
    mapping(address => uint256) public lastHatch;
    mapping(address => address) public referrals;
    uint256 public marketEggs;

    function ChickenFarm() public {
        ceoAddress = msg.sender;
    }

    function hatchEggs(address ref) public {
        require(initialized);

        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }

        uint256 eggsUsed = getMyEggs();
        uint256 newChicken = eggsUsed.div(EGGS_TO_HATCH_1CHICKEN);
        hatcheryChicken[msg.sender] = hatcheryChicken[msg.sender].add(newChicken);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;

        // Send referral eggs
        claimedEggs[referrals[msg.sender]] = claimedEggs[referrals[msg.sender]].add(eggsUsed.div(10));

        // Boost market to nerf chicken hoarding
        marketEggs = marketEggs.add(eggsUsed.div(5));
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

        uint256 eggsBought = calculateEggBuy(msg.value, SafeMath.sub(this.balance, msg.value));
        eggsBought = eggsBought.sub(devFee(eggsBought));
        claimedEggs[msg.sender] = claimedEggs[msg.sender].add(eggsBought);
        ceoAddress.transfer(devFee(msg.value));
    }

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns (uint256) {
        return PSN.mul(bs).div(PSNH.add(PSN.mul(rs).add(PSNH.mul(rt)).div(rt)));
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
        return amount.mul(4).div(100);
    }

    function seedMarket(uint256 eggs) public payable {
        require(marketEggs == 0);
        initialized = true;
        marketEggs = eggs;
    }

    function getFreeChicken() public {
        require(initialized);
        require(hatcheryChicken[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        hatcheryChicken[msg.sender] = STARTING_CHICKEN;
    }

    function getBalance() public view returns (uint256) {
        return this.balance;
    }

    function getMyChicken() public view returns (uint256) {
        return hatcheryChicken[msg.sender];
    }

    function getMyEggs() public view returns (uint256) {
        return claimedEggs[msg.sender].add(getEggsSinceLastHatch(msg.sender));
    }

    function getEggsSinceLastHatch(address adr) public view returns (uint256) {
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
```