```solidity
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

        uint256 slugs = calculateSlugs(msg.value, true);
        playerSlugs[msg.sender] = playerSlugs[msg.sender].add(slugs);
        totalSlugs = totalSlugs.add(slugs);
        distributeFunds(msg.value);
        playerBalance[msg.sender] = playerBalance[msg.sender].add(slugs);

        emit BoughtSlug(msg.sender, msg.value, slugs);

        if (slugs >= 200) {
            updateDriver();
        }
    }

    function skipAhead() public {
        require(gameStarted);
        require(playerBalance[msg.sender] > 0);
        require(now <= raceEndTime);

        uint256 amount = playerBalance[msg.sender];
        uint256 slugs = calculateSlugs(amount, false);
        playerBalance[msg.sender] = 0;
        totalSlugs = totalSlugs.add(slugs);
        distributeFunds(amount);
        playerSlugs[msg.sender] = playerSlugs[msg.sender].add(slugs);

        emit SkippedAhead(msg.sender, amount, slugs);

        if (slugs >= 200) {
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
        playerDividends[msg.sender] = playerDividends[msg.sender].sub(THROW_SLUG_REQ.mul(totalSlugs).div(totalSlugs));

        emit ThrewSlug(msg.sender);
    }

    function jumpOut() public {
        require(gameStarted);
        require(msg.sender == currentDriver);
        require(msg.sender != owner);

        uint256 miles = calculateMiles();
        playerMiles[currentDriver] = playerMiles[currentDriver].add(miles);
        uint256 reward = calculateReward(miles);
        totalSlugs = totalSlugs.sub(reward);
        playerBalance[msg.sender] = playerBalance[msg.sender].add(reward);

        currentDriver = owner;
        lastRaceTime = now;

        emit JumpedOut(msg.sender, reward);
    }

    function tradeMiles() public {
        require(playerMiles[msg.sender] >= MILE_REQ);
        require(msg.sender != currentDriver);

        uint256 miles = playerMiles[msg.sender].div(MILE_REQ);
        if (miles > 20) {
            miles = 20;
        }

        uint256 reward = calculateReward(miles);
        totalSlugs = totalSlugs.sub(reward);
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
        totalSlugs = totalSlugs.add(msg.value);
        emit BoostedPot(msg.sender, msg.value);
    }

    function calculateSlugs(uint256 amount, bool isBuy) public view returns (uint256) {
        uint256 cost;
        if (isBuy) {
            cost = SLUG_COST_FLOOR;
        } else {
            cost = calculateSlugCost(false);
        }
        return amount.div(cost);
    }

    function calculateMiles() public view returns (uint256) {
        uint256 timeElapsed = now.sub(lastRaceTime);
        return timeElapsed.mul(ACCEL_FACTOR).div(MIN_SPEED);
    }

    function calculateReward(uint256 miles) public view returns (uint256) {
        return miles.mul(totalSlugs).div(100);
    }

    function distributeFunds(uint256 amount) private {
        uint256 driverShare = amount.mul(3).div(5);
        uint256 potShare = amount.sub(driverShare);
        playerBalance[currentDriver] = playerBalance[currentDriver].add(driverShare);
        totalSlugs = totalSlugs.add(potShare);
    }

    function updateDriver() private {
        uint256 miles = calculateMiles();
        playerMiles[currentDriver] = playerMiles[currentDriver].add(miles);
        uint256 reward = calculateReward(miles);
        totalSlugs = totalSlugs.sub(reward);
        playerBalance[currentDriver] = playerBalance[currentDriver].add(reward);

        currentDriver = msg.sender;
        lastRaceTime = now;

        emit TookWheel(msg.sender, reward);
    }

    function calculateSlugCost(bool isBuy) public view returns (uint256) {
        if (isBuy) {
            return SLUG_COST_FLOOR;
        } else {
            return totalSlugs.div(10000);
        }
    }

    function calculateMilesDriven() public view returns (uint256) {
        uint256 timeElapsed = now.sub(lastRaceTime);
        return timeElapsed.mul(ACCEL_FACTOR).div(MIN_SPEED);
    }

    function getPlayerBalance(address player) public view returns (uint256) {
        return playerBalance[player];
    }

    function getPlayerMiles(address player) public view returns (uint256) {
        return playerMiles[player];
    }

    function getPlayerSlugs(address player) public view returns (uint256) {
        return playerSlugs[player];
    }

    function getPlayerDividends(address player) public view returns (uint256) {
        return playerDividends[player];
    }

    function getPlayerLastRaceTime(address player) public view returns (uint256) {
        return playerLastRaceTime[player];
    }

    function getPlayerCurrentDriver() public view returns (address) {
        return currentDriver;
    }

    function getPlayerRaceEndTime() public view returns (uint256) {
        return raceEndTime;
    }

    function getPlayerTotalSlugs() public view returns (uint256) {
        return totalSlugs;
    }

    function getPlayerThroneBalance() public view returns (uint256) {
        return throneBalance;
    }

    function getPlayerThroneAddress() public view returns (address) {
        return throneAddress;
    }

    function getPlayerOwner() public view returns (address) {
        return owner;
    }

    function getPlayerGameStarted() public view returns (bool) {
        return gameStarted;
    }

    function getPlayerLastRaceTime() public view returns (uint256) {
        return lastRaceTime;
    }

    function getPlayerRaceDuration() public view returns (uint256) {
        return RACE_DURATION;
    }

    function getPlayerThrowSlugReq() public view returns (uint256) {
        return THROW_SLUG_REQ;
    }

    function getPlayerMileReq() public view returns (uint256) {
        return MILE_REQ;
    }

    function getPlayerSlugCostFloor() public view returns (uint256) {
        return SLUG_COST_FLOOR;
    }

    function getPlayerAccelFactor() public view returns (uint256) {
        return ACCEL_FACTOR;
    }

    function getPlayerMinSpeed() public view returns (uint256) {
        return MIN_SPEED;
    }

    function getPlayerMaxBuy() public view returns (uint256) {
        return MAX_BUY;
    }

    function getPlayerMaxSlugs() public view returns (uint256) {
        return MAX_SLUGS;
    }

    function getPlayerMaxMiles() public view returns (uint256) {
        return MAX_MILES;
    }

    function getPlayerMaxDividends() public view returns (uint256) {
        return MAX_DIVIDENDS;
    }

    function getPlayerMaxBalance() public view returns (uint256) {
        return MAX_BALANCE;
    }

    function getPlayerMaxPot() public view returns (uint256) {
        return MAX_POT;
    }

    function getPlayerMaxThrone() public view returns (uint256) {
        return MAX_THRONE;
    }

    function getPlayerMaxThroneBalance() public view returns (uint256) {
        return MAX_THRONE_BALANCE;
    }

    function getPlayerMaxThroneAddress() public view returns (address) {
        return MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxOwner() public view returns (address) {
        return MAX_OWNER;
    }

    function getPlayerMaxGameStarted() public view returns (bool) {
        return MAX_GAME_STARTED;
    }

    function getPlayerMaxLastRaceTime() public view returns (uint256) {
        return MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxRaceDuration() public view returns (uint256) {
        return MAX_RACE_DURATION;
    }

    function getPlayerMaxThrowSlugReq() public view returns (uint256) {
        return MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMileReq() public view returns (uint256) {
        return MAX_MILE_REQ;
    }

    function getPlayerMaxSlugCostFloor() public view returns (uint256) {
        return MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxAccelFactor() public view returns (uint256) {
        return MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMinSpeed() public view returns (uint256) {
        return MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_BUY;
    }

    function getPlayerMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MILES;
    }

    function getPlayerMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_POT;
    }

    function getPlayerMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxOwner() public view returns (address) {
        return MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUG_COST_FLOOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxAccelFactor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_ACCEL_FACTOR;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMinSpeed() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MIN_SPEED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBuy() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BUY;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugs() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_SLUGS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMiles() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILES;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxDividends() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_DIVIDENDS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxPot() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_POT;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrone() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneBalance() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_BALANCE;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThroneAddress() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THRONE_ADDRESS;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxOwner() public view returns (address) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_OWNER;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxGameStarted() public view returns (bool) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_GAME_STARTED;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxLastRaceTime() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_LAST_RACE_TIME;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxRaceDuration() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_RACE_DURATION;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxThrowSlugReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_THROW_SLUG_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMileReq() public view returns (uint256) {
        return MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MAX_MILE_REQ;
    }

    function getPlayerMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxMaxSlugCostFloor() public view returns (uint256) {
        return MAX_MAX_MAX_MAX