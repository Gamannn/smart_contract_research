```solidity
pragma solidity ^0.4.24;

contract DeObfuscatedContract {
    uint256 public marketPoohs;
    address public ceoAddress;
    bool public initialized;
    mapping(address => uint256) public poohBalance;
    mapping(address => uint256) public lastHatch;
    mapping(address => uint256) public claimedPoohs;
    mapping(address => address) public referrals;

    constructor() public {
        ceoAddress = msg.sender;
    }

    function hatchPoohs(address ref) public {
        require(initialized);
        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 poohsUsed = getMyPoohs();
        uint256 newPoohs = poohsUsed / 5;
        poohBalance[msg.sender] = poohBalance[msg.sender] + newPoohs;
        claimedPoohs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        claimedPoohs[referrals[msg.sender]] = claimedPoohs[referrals[msg.sender]] + newPoohs / 5;
        marketPoohs = marketPoohs + poohsUsed / 10;
    }

    function sellPoohs() public {
        require(initialized);
        uint256 hasPoohs = getMyPoohs();
        uint256 poohValue = calculatePoohSell(hasPoohs);
        uint256 fee = devFee(poohValue);
        poohBalance[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketPoohs = marketPoohs + hasPoohs;
        ceoAddress.transfer(fee);
        msg.sender.transfer(poohValue - fee);
    }

    function buyPoohs() public payable {
        require(initialized);
        uint256 poohsBought = calculatePoohBuy(msg.value, address(this).balance - msg.value);
        poohsBought = poohsBought - devFee(poohsBought);
        ceoAddress.transfer(devFee(msg.value));
        claimedPoohs[msg.sender] = claimedPoohs[msg.sender] + poohsBought;
    }

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns (uint256) {
        return (PSN * bs) / (PSNH + ((PSN * rs + PSNH * rt) / rt));
    }

    function calculatePoohSell(uint256 poohs) public view returns (uint256) {
        return calculateTrade(poohs, marketPoohs, address(this).balance);
    }

    function calculatePoohBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketPoohs);
    }

    function devFee(uint256 amount) public pure returns (uint256) {
        return amount * 4 / 100;
    }

    function seedMarket(uint256 amount) public payable {
        require(marketPoohs == 0);
        initialized = true;
        marketPoohs = amount;
    }

    function getFreePoohs() public payable {
        require(initialized);
        require(msg.value == 0.001 ether);
        ceoAddress.transfer(msg.value);
        require(poohBalance[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        poohBalance[msg.sender] = STARTING_POOHS;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyPoohs() public view returns (uint256) {
        return claimedPoohs[msg.sender] + getPoohsSinceLastHatch(msg.sender);
    }

    function getPoohsSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(SECONDS_IN_A_DAY, now - lastHatch[adr]);
        return secondsPassed * poohBalance[adr];
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    uint256 constant PSN = 10000;
    uint256 constant PSNH = 5000;
    uint256 constant STARTING_POOHS = 300;
    uint256 constant SECONDS_IN_A_DAY = 86400;
}
```