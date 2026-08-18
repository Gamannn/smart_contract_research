pragma solidity ^0.4.24;

contract RacingGame {
    using SafeMath for uint256;

    event WithdrewBalance(address indexed player, uint256 amount);
    event BoughtSlug(address indexed player, uint256 amount, uint256 slugs);
    event SkippedAhead(address indexed player, uint256 amount, uint256 slugs);
    event TradedMile(address indexed player, uint256 amount, uint256 miles);
    event BecameDriver(address indexed player, uint256 amount);
    event TookWheel(address indexed player, uint256 amount);
    event ThrewSlug(address indexed player);
    event JumpedOut(address indexed player, uint256 amount);
    event TimeWarped(address indexed player, uint256 indexed loop, uint256 amount);
    event NewLoop(address indexed player, uint256 indexed loop);
    event PaidThrone(address indexed player, uint256 amount);
    event BoostedPot(address indexed player, uint256 amount);

    uint256 constant public RACE_DURATION = 604800;
    bool public gameStarted;
    address public currentDriver;
    mapping(address => uint256) public playerMiles;

    constructor() public {
        owner = msg.sender;
        gameStarted = false;
    }

    function startGame() public payable {
        require(!gameStarted);
        require(msg.sender == owner);
        raceEndTime = now.add(RACE_DURATION);
        gameStarted = true;
        lastRaceTime = now;
        currentDriver = owner;
    }

    function buySlugs(uint256 amount) public payable {
        require(gameStarted);
        require(tx.origin == msg.sender);
        require(msg.value <= 1 ether);
        require(now <= raceEndTime);

        uint256 slugsBought = calculateSlugs(msg.value, true);
        playerSlugs[msg.sender] = playerSlugs[msg.sender].add(slugsBought);
        totalSlugs = totalSlugs.add(slugsBought);
        distributeFunds(msg.value);
        playerBalance[msg.sender] = playerBalance[msg.sender].add(slugsBought);

        emit BoughtSlug(msg.sender, msg.value, slugsBought);

        if (slugsBought >= 200) {
            updateDriver();
        }
    }

    function skipAhead() public {
        require(gameStarted);
        require(playerBalance[msg.sender] > 0);
        require(now <= raceEndTime);

        uint256 amount = playerBalance[msg.sender];
        uint256 slugsSkipped = calculateSlugs(amount, false);
        playerBalance[msg.sender] = 0;
        totalSlugs = totalSlugs.add(slugsSkipped);
        distributeFunds(amount);
        playerSlugs[msg.sender] = playerSlugs[msg.sender].add(slugsSkipped);

        emit SkippedAhead(msg.sender, amount, slugsSkipped);

        if (slugsSkipped >= 200) {
            updateDriver();
        }
    }

    function withdrawBalance() public {
        require(playerBalance[msg.sender] > 0);

        uint256 amount = playerBalance[msg.sender];
        playerBalance[msg.sender] = 0;
        msg.sender.transfer(amount);

        emit WithdrewBalance(msg.sender, amount);
    }

    function throwSlug() public {
        require(gameStarted);
        require(playerSlugs[msg.sender] >= THROW_SLUG_REQ);
        require(now <= raceEndTime);

        totalSlugs = totalSlugs.sub(THROW_SLUG_REQ);
        playerSlugs[msg.sender] = playerSlugs[msg.sender].sub(THROW_SLUG_REQ);
        playerDividends[msg.sender] = playerDividends[msg.sender].sub(THROW_SLUG_REQ.mul(slugValue));

        emit ThrewSlug(msg.sender);
    }

    function jumpOut() public {
        require(gameStarted);
        require(msg.sender == currentDriver);
        require(msg.sender != owner);

        uint256 miles = calculateMiles();
        playerMiles[currentDriver] = playerMiles[currentDriver].add(miles);
        uint256 reward = calculateReward(miles);
        totalPot = totalPot.sub(reward);
        playerBalance[msg.sender] = playerBalance[msg.sender].add(reward);

        currentDriver = owner;
        lastRaceTime = now;

        emit JumpedOut(msg.sender, reward);
    }

    function tradeMiles() public {
        require(playerMiles[msg.sender] >= MILE_REQ);
        require(msg.sender != currentDriver);
        require(msg.sender != owner);

        uint256 miles = playerMiles[msg.sender].div(MILE_REQ);
        if (miles > 20) {
            miles = 20;
        }

        uint256 reward = calculateReward(miles);
        totalPot = totalPot.sub(reward);
        playerMiles[msg.sender] = playerMiles[msg.sender].sub(miles.mul(MILE_REQ));
        playerBalance[msg.sender] = playerBalance[msg.sender].add(reward);

        emit TradedMile(msg.sender, reward, miles);
    }

    function payThrone() public {
        uint256 amount = throneBalance;
        throneBalance = 0;
        if (!throneAddress.call.value(amount)()) {
            revert();
        }
        emit PaidThrone(msg.sender, amount);
    }

    function() public payable {
        totalPot = totalPot.add(msg.value);
        emit BoostedPot(msg.sender, msg.value);
    }

    function calculateSlugs(uint256 amount, bool isBuy) public view returns (uint256) {
        uint256 slugCost;
        if (isBuy) {
            slugCost = SLUG_COST_FLOOR;
        } else {
            slugCost = calculateSlugCost(false);
        }
        return amount.div(slugCost);
    }

    function calculateSlugCost(bool isBuy) public view returns (uint256) {
        if (isBuy) {
            return (slugCostBase.mul(slugValue.div(SLUG_COST_FLOOR))).div(currentLoop);
        } else {
            return (slugCostBase.mul(slugValue.div(SLUG_COST_FLOOR))).div(currentLoop.add(1));
        }
    }

    function calculateMiles() public view returns (uint256) {
        uint256 timeElapsed = now.sub(lastRaceTime);
        return timeElapsed.mul(ACCEL_FACTOR).div(MIN_SPEED).div(RACE_DURATION);
    }

    function calculateReward(uint256 miles) public view returns (uint256) {
        return miles.mul(slugValue).div(100);
    }

    function distributeFunds(uint256 amount) private {
        totalPot = totalPot.add(amount.mul(3).div(5));
        throneBalance = throneBalance.add(amount.div(5));
        playerDividends[msg.sender] = playerDividends[msg.sender].add(amount.div(10));
    }

    function updateDriver() private {
        uint256 reward = calculateReward(1);
        playerMiles[currentDriver] = playerMiles[currentDriver].add(reward);
        totalPot = totalPot.sub(reward);
        playerBalance[currentDriver] = playerBalance[currentDriver].add(reward);

        if (now >= raceEndTime) {
            currentDriver = owner;
            raceEndTime = now.add(RACE_DURATION);
            currentLoop = currentLoop.add(1);
            emit NewLoop(msg.sender, currentLoop);
        } else {
            currentDriver = msg.sender;
            emit TookWheel(msg.sender, reward);
        }
        lastRaceTime = now;
    }

    address public owner;
    uint256 public raceEndTime;
    uint256 public lastRaceTime;
    uint256 public totalPot;
    uint256 public throneBalance;
    uint256 public totalSlugs;
    uint256 public slugValue;
    uint256 public currentLoop;
    uint256 public slugCostBase;
    uint256 public SLUG_COST_FLOOR;
    uint256 public THROW_SLUG_REQ;
    uint256 public MILE_REQ;
    uint256 public ACCEL_FACTOR;
    uint256 public MIN_SPEED;
    uint256 public RACE_DURATION;

    mapping(address => uint256) public playerBalance;
    mapping(address => uint256) public playerSlugs;
    mapping(address => uint256) public playerDividends;
    address public throneAddress;
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
