pragma solidity ^0.4.18;

contract SpermMarket {
    uint256 public constant CELLS_TO_MAKE_1_SPERM = 86400;
    uint256 public constant STARTING_SPERM = 500000;
    uint256 public constant SPERM_LORD_REQ = 500000;
    uint256 public constant PSN = 10000;
    uint256 public constant PSNH = 5000;
    uint256 public constant INITIAL_MARKET_CELLS = 500;
    uint256 public constant INITIAL_SPERM = 1;
    uint256 public constant SPERM_COST = 0.001 ether;

    bool public initialized = false;
    address public spermLordAddress;
    uint256 public marketCells;
    mapping(address => uint256) public spermBalance;
    mapping(address => uint256) public claimedCells;
    mapping(address => uint256) public lastClaim;
    mapping(address => address) public referrals;

    function SpermMarket() public {
        spermLordAddress = msg.sender;
    }

    function hatchEggs(address ref) public {
        require(initialized);
        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 cellsUsed = getMyCells();
        uint256 newSperm = cellsUsed / CELLS_TO_MAKE_1_SPERM;
        spermBalance[msg.sender] += newSperm;
        claimedCells[msg.sender] = 0;
        lastClaim[msg.sender] = now;
        claimedCells[referrals[msg.sender]] += cellsUsed / 5;
        marketCells += cellsUsed / 10;
    }

    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyCells();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        claimedCells[msg.sender] = 0;
        lastClaim[msg.sender] = now;
        marketCells += hasEggs;
        spermLordAddress.transfer(fee);
        msg.sender.transfer(eggValue - fee);
    }

    function buyEggs() public payable {
        require(initialized);
        uint256 eggsBought = calculateEggBuy(msg.value, this.balance - msg.value);
        eggsBought -= devFee(eggsBought);
        claimedCells[msg.sender] += eggsBought;
        spermLordAddress.transfer(devFee(msg.value));
    }

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns (uint256) {
        return PSN * bs / (PSNH + (PSN * rs + PSNH * rt) / rt);
    }

    function calculateEggSell(uint256 eggs) public view returns (uint256) {
        return calculateTrade(eggs, marketCells, this.balance);
    }

    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketCells);
    }

    function calculateEggBuySimple(uint256 eth) public view returns (uint256) {
        return calculateEggBuy(eth, this.balance);
    }

    function devFee(uint256 amount) public view returns (uint256) {
        return amount * 4 / 100;
    }

    function seedMarket(uint256 eggs) public payable {
        require(marketCells == 0);
        initialized = true;
        marketCells = eggs;
    }

    function getFreeEggs() public payable {
        require(initialized);
        require(msg.value == SPERM_COST);
        spermLordAddress.transfer(msg.value);
        require(spermBalance[msg.sender] == 0);
        lastClaim[msg.sender] = now;
        spermBalance[msg.sender] = STARTING_SPERM;
    }

    function getBalance() public view returns (uint256) {
        return this.balance;
    }

    function getMySperm() public view returns (uint256) {
        return spermBalance[msg.sender];
    }

    function becomeSpermLord() public {
        require(initialized);
        require(msg.sender != spermLordAddress);
        require(spermBalance[msg.sender] >= SPERM_LORD_REQ);
        spermBalance[msg.sender] -= SPERM_LORD_REQ;
        SPERM_LORD_REQ += SPERM_LORD_REQ;
        spermLordAddress = msg.sender;
    }

    function getSpermLordReq() public view returns (uint256) {
        return SPERM_LORD_REQ;
    }

    function getMyCells() public view returns (uint256) {
        return claimedCells[msg.sender] + getCellsSinceLastHatch(msg.sender);
    }

    function getCellsSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(CELLS_TO_MAKE_1_SPERM, now - lastClaim[adr]);
        return secondsPassed * spermBalance[adr];
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
