pragma solidity ^0.4.18;

interface TokenInterface {
    function transfer(address to, uint256 value) public returns (bool success);
}

contract BaseContract {
    function buy(address) public payable returns(uint256);
    function transfer(address, uint256) public returns(bool);
    function balanceOf(address) public view returns(uint256);
    function myTokens(bool) public view returns(uint256);
    function reinvest() public;
}

contract ContractWrapper {
    BaseContract public tokenContract;

    function ContractWrapper(address _baseContract) public {
        tokenContract = BaseContract(_baseContract);
    }

    modifier onlyTokenContract() {
        require(msg.sender == address(tokenContract));
        _;
    }

    function handleTransaction(address user, uint256 amount, bytes data) external returns (bool);
}

contract MainContract is ContractWrapper {
    uint256 public SECONDS_PER_DAY = 86400;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    address public ceoAddress;
    bool public initialized = false;

    function MainContract(address _baseContract) ContractWrapper(_baseContract) public {
        ceoAddress = msg.sender;
    }

    function() payable public {}

    function handleTransaction(address user, uint256 amount, bytes data) external onlyTokenContract returns (bool) {
        require(initialized);
        require(!isContract(user));
        require(amount >= 1 finney);

        uint256 balance = tokenContract.balanceOf(address(this));
        uint256 eggsBought = calculateEggBuy(amount, safeSub(balance, amount));
        eggsBought = safeSub(eggsBought, calculateDevFee(eggsBought));

        tokenContract.reinvest();
        tokenContract.transfer(ceoAddress, calculateDevFee(amount));

        hatcheryMiners[user] = safeAdd(hatcheryMiners[user], eggsBought);
        return true;
    }

    function hatchEggs(address ref) public {
        require(initialized);
        require(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender);

        if (ref != msg.sender) {
            referrals[msg.sender] = ref;
        }

        uint256 eggsUsed = getMyEggs();
        uint256 newMiners = safeDiv(eggsUsed, EGGS_TO_HATCH_1MINER);
        hatcheryMiners[msg.sender] = safeAdd(hatcheryMiners[msg.sender], newMiners);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;

        // send referral eggs
        hatcheryMiners[referrals[msg.sender]] = safeAdd(hatcheryMiners[referrals[msg.sender]], safeDiv(eggsUsed, 5));

        // boost market to nerf miners hoarding
        marketEggs = safeAdd(marketEggs, safeDiv(eggsUsed, 10));
    }

    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = calculateDevFee(eggValue);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = safeAdd(marketEggs, hasEggs);

        tokenContract.reinvest();
        tokenContract.transfer(ceoAddress, fee);
        tokenContract.transfer(msg.sender, safeSub(eggValue, fee));
    }

    function seedMarket(uint256 eggs) public {
        require(marketEggs == 0);
        require(msg.sender == ceoAddress);
        initialized = true;
        marketEggs = eggs;
    }

    function reinvest() public {
        if (tokenContract.myTokens(true) > 1) {
            tokenContract.reinvest();
        }
    }

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        return safeDiv(safeMul(PSN, bs), safeAdd(PSNH, safeDiv(safeAdd(safeMul(PSN, rs), safeMul(PSNH, rt)), rt)));
    }

    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs, marketEggs, tokenContract.balanceOf(address(this)));
    }

    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth, tokenContract.balanceOf(address(this)));
    }

    function calculateDevFee(uint256 amount) public view returns(uint256) {
        return safeDiv(safeMul(amount, 4), 100);
    }

    function getMyMiners() public view returns(uint256) {
        return hatcheryMiners[msg.sender];
    }

    function getMyEggs() public view returns(uint256) {
        return safeAdd(claimedEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
    }

    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(SECONDS_PER_DAY, safeSub(now, lastHatch[adr]));
        return safeMul(secondsPassed, hatcheryMiners[adr]);
    }

    function getMyTokens() public view returns(uint256) {
        return tokenContract.myTokens(true);
    }

    function getBalance() public view returns(uint256) {
        return tokenContract.balanceOf(address(this));
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    uint256 constant PSN = 10000;
    uint256 constant PSNH = 5000;
    uint256 constant EGGS_TO_HATCH_1MINER = 86400;
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