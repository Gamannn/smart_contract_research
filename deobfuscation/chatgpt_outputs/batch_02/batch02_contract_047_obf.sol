```solidity
pragma solidity ^0.4.24;

contract SnailGame {
    using SafeMath for uint;

    event WithdrewEarnings(address indexed player, uint amount);
    event ClaimedDividends(address indexed player, uint amount);
    event BoughtSnail(address indexed player, uint ethSpent, uint snailsBought);
    event SoldSnail(address indexed player, uint ethReceived, uint snailsSold);
    event HatchedSnail(address indexed player, uint ethSpent, uint snailsHatched);
    event FedFrogKing(address indexed player, uint ethSpent, uint snailsFed);
    event Ascended(address indexed player, uint ethSpent, uint indexed newPharaoh);
    event BecamePharaoh(address indexed player, uint indexed newPharaoh);
    event NewDividends(uint amount);

    uint256 public hatcheryTime = 86400;
    uint256 public maxBuy = 4 ether;
    uint256 public maxSell = 20000000000000;
    uint256 public maxSnails = 10000000;
    uint256 public maxSnailHatch = 4000000000000000000;
    uint256 public godTimerStart = 1080000;
    uint256 public godTimerBoost = 300;
    uint256 public pharaohReqStart = 6;
    uint256 public pharaohReqBoost = 5;

    mapping(address => uint256) public playerEarnings;
    mapping(address => uint256) public playerSnails;
    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public lastHatch;
    mapping(address => uint256) public lastFed;
    mapping(address => uint256) public lastAscend;

    address public owner;
    address public currentPharaoh;
    uint256 public godTimer;
    uint256 public pharaohTimer;
    uint256 public totalSnails;
    uint256 public totalDividends;
    uint256 public totalHatched;
    uint256 public totalFed;
    uint256 public totalAscended;

    constructor() public {
        owner = msg.sender;
        currentPharaoh = owner;
        godTimer = now + hatcheryTime;
        pharaohTimer = now;
        totalSnails = 1;
        totalDividends = 0;
        totalHatched = 0;
        totalFed = 0;
        totalAscended = 0;
    }

    function withdrawEarnings() public {
        require(playerEarnings[msg.sender] > 0);
        uint256 earnings = playerEarnings[msg.sender];
        playerEarnings[msg.sender] = 0;
        msg.sender.transfer(earnings);
        emit WithdrewEarnings(msg.sender, earnings);
    }

    function claimDividends() public {
        uint256 dividends = calculateDividends(msg.sender);
        if (dividends > 0) {
            playerEarnings[msg.sender] = playerEarnings[msg.sender].add(dividends);
            emit ClaimedDividends(msg.sender, dividends);
        }
    }

    function buySnail(address referrer) public payable {
        require(totalSnails > 0, "game hasn't started yet");
        require(tx.origin == msg.sender, "contracts not allowed");
        require(msg.value <= maxBuy, "maximum buy = 4 ETH");

        uint256 snailsBought = computeBuy(msg.value);
        playerSnails[msg.sender] = playerSnails[msg.sender].add(snailsBought);
        lastClaim[msg.sender] = now;
        emit BoughtSnail(msg.sender, msg.value, snailsBought);
    }

    function sellSnail(uint256 snailsToSell) public {
        require(totalSnails > 0, "game hasn't started yet");
        require(playerSnails[msg.sender] >= snailsToSell, "not enough snails to sell");

        claimDividends();
        uint256 ethReceived = computeSell(snailsToSell);
        playerSnails[msg.sender] = playerSnails[msg.sender].sub(snailsToSell);
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(ethReceived);
        emit SoldSnail(msg.sender, ethReceived, snailsToSell);
    }

    function hatchSnail() public payable {
        require(totalSnails > 0, "game hasn't started yet");
        require(msg.value > 0, "need ETH to hatch eggs");

        uint256 snailsHatched = computeHatch(msg.value);
        playerSnails[msg.sender] = playerSnails[msg.sender].add(snailsHatched);
        lastHatch[msg.sender] = now;
        emit HatchedSnail(msg.sender, msg.value, snailsHatched);
    }

    function feedFrogKing() public {
        require(totalSnails > 0, "game hasn't started yet");

        uint256 snailsFed = computeFeed(msg.sender);
        playerSnails[msg.sender] = playerSnails[msg.sender].sub(snailsFed);
        lastFed[msg.sender] = now;
        emit FedFrogKing(msg.sender, snailsFed, snailsFed);
    }

    function ascend() public {
        require(totalSnails > 0, "game hasn't started yet");
        require(now >= godTimer, "current pharaoh hasn't ascended yet");

        currentPharaoh = msg.sender;
        godTimer = now + godTimerStart;
        emit Ascended(msg.sender, godTimer, totalSnails);
    }

    function becomePharaoh(uint256 snailsToSacrifice) public {
        require(totalSnails > 0, "game hasn't started yet");
        require(playerSnails[msg.sender] >= snailsToSacrifice, "not enough snails in hatchery");

        if (now >= pharaohTimer) {
            ascend();
        }

        uint256 snailsRequired = computePharaohReq();
        if (snailsToSacrifice >= snailsRequired) {
            currentPharaoh = msg.sender;
            pharaohTimer = now + pharaohReqStart;
            emit BecamePharaoh(msg.sender, pharaohTimer);
        }
    }

    function() public payable {
        totalDividends = totalDividends.add(msg.value);
        emit NewDividends(msg.value);
    }

    function calculateDividends(address player) public view returns (uint256) {
        uint256 timePassed = now.sub(lastClaim[player]);
        uint256 dividends = timePassed.mul(totalDividends).div(totalSnails);
        return dividends;
    }

    function computeBuy(uint256 ethAmount) internal view returns (uint256) {
        return ethAmount.mul(totalSnails).div(totalDividends);
    }

    function computeSell(uint256 snailsToSell) internal view returns (uint256) {
        return snailsToSell.mul(totalDividends).div(totalSnails);
    }

    function computeHatch(uint256 ethAmount) internal view returns (uint256) {
        return ethAmount.mul(totalSnails).div(totalDividends);
    }

    function computeFeed(address player) internal view returns (uint256) {
        uint256 timePassed = now.sub(lastFed[player]);
        uint256 snailsFed = timePassed.mul(playerSnails[player]).div(totalSnails);
        return snailsFed;
    }

    function computePharaohReq() internal view returns (uint256) {
        return totalSnails.mul(pharaohReqStart).div(pharaohReqBoost);
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