```solidity
pragma solidity ^0.4.24;

contract HyperLords {
    using SafeMath for uint256;
    
    event WithdrewBalance(address indexed player, uint256 amount);
    event BoughtSlug(address indexed player, uint256 ethAmount, uint256 slugAmount);
    event SkippedAhead(address indexed player, uint256 ethAmount, uint256 slugAmount);
    event TradedMile(address indexed player, uint256 ethAmount, uint256 mileAmount);
    event BecameDriver(address indexed player, uint256 timerBoost);
    event TookWheel(address indexed player, uint256 timerBoost);
    event ThrewSlug(address indexed player);
    event JumpedOut(address indexed player, uint256 reward);
    event TimeWarped(address indexed player, uint256 indexed loop, uint256 reward);
    event NewLoop(address indexed player, uint256 indexed loop);
    event PaidThrone(address indexed player, uint256 amount);
    event BoostedPot(address indexed player, uint256 amount);
    
    uint256 constant public WEEK = 604800;
    uint256 constant public DRIVER_TIMER_BOOST = 360;
    uint256 constant public HYPERSPEED_LENGTH = 3600;
    uint256 constant public SLUG_COST_FLOOR = 25000000000000;
    uint256 constant public ACCEL_FACTOR = 100;
    uint256 constant public MIN_SPEED = 672;
    uint256 constant public MAX_SPEED = 1000;
    uint256 constant public TOKEN_MAX_BUY = 1000000000000000000;
    uint256 constant public MILE_REQ = 100;
    uint256 constant public THROW_SLUG_REQ = 10;
    uint256 constant public RACE_TIMER_START = 6000;
    uint256 constant public LOOP_POT_SPLIT = 20;
    uint256 constant public DIV_PER_SLUG = 10000;
    uint256 constant public SLUG_BANK_DIV = 5;
    
    bool public gameStarted;
    address public driver;
    mapping(address => uint256) public milesDriven;
    
    address public owner;
    address public throne;
    uint256 public raceEndTime;
    uint256 public loop;
    uint256 public slugCost;
    uint256 public slugBank;
    uint256 public loopChest;
    uint256 public totalSlugs;
    uint256 public lastHijack;
    
    mapping(address => uint256) public playerSlugs;
    mapping(address => uint256) public playerDividends;
    mapping(address => uint256) public playerBalance;
    
    constructor() public {
        owner = msg.sender;
        gameStarted = false;
        throne = 0x261d650a521103428C6827a11fc0CBCe96D74DBc;
    }
    
    function startRace() public payable {
        require(gameStarted == false);
        require(msg.sender == owner);
        
        raceEndTime = now.add(WEEK).add(RACE_TIMER_START);
        gameStarted = true;
        lastHijack = now;
        driver = owner;
        slugCost = SLUG_COST_FLOOR;
        loop = 1;
    }
    
    function updatePot(uint256 amount) private {
        totalSlugs = totalSlugs.add(amount.mul(3).div(5).div(slugCost));
        slugBank = slugBank.add(amount.div(5));
        loopChest = loopChest.add(amount.mul(DIV_PER_SLUG).div(10));
        slugCost = slugCost.add(amount.mul(3).div(5).div(totalSlugs));
        
        uint256 dividends = calculateDividends(msg.sender);
        if(dividends > 0) {
            playerDividends[msg.sender] = playerDividends[msg.sender].add(dividends);
            playerBalance[msg.sender] = playerBalance[msg.sender].add(dividends);
        }
    }
    
    function becomeDriver() private {
        uint256 miles = computeMileDriven();
        milesDriven[driver] = milesDriven[driver].add(miles);
        
        if(now.add(DRIVER_TIMER_BOOST) >= raceEndTime) {
            driver = address(0);
            raceEndTime = driver == address(0) ? now.add(DRIVER_TIMER_BOOST) : raceEndTime.add(DRIVER_TIMER_BOOST);
            emit TookWheel(msg.sender, DRIVER_TIMER_BOOST);
        } else {
            driver = msg.sender;
            raceEndTime = raceEndTime.add(HYPERSPEED_LENGTH);
            emit BecameDriver(msg.sender, HYPERSPEED_LENGTH);
        }
        
        lastHijack = now;
    }
    
    function finishRace() public {
        require(gameStarted == true, "game hasn't started yet");
        require(now >= raceEndTime, "race isn't finished yet");
        
        uint256 miles = computeMileDriven();
        milesDriven[driver] = milesDriven[driver].add(miles);
        
        raceEndTime = now.add(WEEK).add(RACE_TIMER_START);
        loop = loop.add(1);
        
        uint256 loopReward = slugBank.div(2);
        slugBank = slugBank.sub(loopReward);
        
        if(driver == owner) {
            uint256 throneCut = loopReward;
            loopChest = loopChest.add(throneCut);
            playerBalance[driver] = playerBalance[driver].add(throneCut);
            emit TimeWarped(msg.sender, loop, throneCut);
        } else {
            emit NewLoop(msg.sender, loop);
        }
        
        lastHijack = now;
        driver = msg.sender;
    }
    
    function buySlugs() public payable {
        require(gameStarted == true, "game hasn't started yet");
        require(tx.origin == msg.sender, "contracts not allowed");
        require(msg.value <= TOKEN_MAX_BUY, "maximum buy = 1 ETH");
        require(now <= raceEndTime, "race is over!");
        
        uint256 slugsBought = calculateSlugBuy(msg.value, true);
        playerDividends[msg.sender] = playerDividends[msg.sender].add(slugsBought.mul(DIV_PER_SLUG).div(slugCost));
        totalSlugs = totalSlugs.add(slugsBought);
        updatePot(msg.value);
        playerSlugs[msg.sender] = playerSlugs[msg.sender].add(slugsBought);
        emit BoughtSlug(msg.sender, msg.value, slugsBought);
        
        if(slugsBought >= 200) {
            becomeDriver();
        }
    }
    
    function sellSlugs() public {
        require(gameStarted == true, "game hasn't started yet");
        claimDividends();
        require(playerBalance[msg.sender] > 0, "no ether to timetravel");
        require(now <= raceEndTime, "race is over!");
        
        uint256 ethAmount = playerBalance[msg.sender];
        uint256 slugAmount = calculateSlugBuy(ethAmount, false);
        playerDividends[msg.sender] = playerDividends[msg.sender].add(slugAmount.mul(DIV_PER_SLUG).div(slugCost));
        playerBalance[msg.sender] = 0;
        totalSlugs = totalSlugs.add(slugAmount);
        updatePot(ethAmount);
        playerSlugs[msg.sender] = playerSlugs[msg.sender].add(slugAmount);
        emit SkippedAhead(msg.sender, ethAmount, slugAmount);
        
        if(slugAmount >= 200) {
            becomeDriver();
        }
    }
    
    function withdraw() public {
        claimDividends();
        require(playerBalance[msg.sender] > 0, "no ether to withdraw");
        uint256 amount = playerBalance[msg.sender];
        playerBalance[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit WithdrewBalance(msg.sender, amount);
    }
    
    function throwSlug() public {
        require(gameStarted == true, "game hasn't started yet");
        require(playerSlugs[msg.sender] >= THROW_SLUG_REQ, "not enough slugs in nest");
        require(now <= raceEndTime, "race is over!");
        
        claimDividends();
        totalSlugs = totalSlugs.sub(THROW_SLUG_REQ);
        playerSlugs[msg.sender] = playerSlugs[msg.sender].sub(THROW_SLUG_REQ);
        playerDividends[msg.sender] = playerDividends[msg.sender].sub(THROW_SLUG_REQ.mul(DIV_PER_SLUG).div(slugCost));
        emit ThrewSlug(msg.sender);
        becomeDriver();
    }
    
    function jumpOut() public {
        require(gameStarted == true, "game hasn't started yet");
        require(msg.sender == driver, "can't jump out if you're not in the car!");
        require(msg.sender != owner, "owner isn't allowed to be driver");
        
        uint256 miles = computeMileDriven();
        milesDriven[driver] = milesDriven[driver].add(miles);
        
        uint256 reward = calculateJumpReward();
        loopChest = loopChest.sub(reward);
        raceEndTime = now.add(DRIVER_TIMER_BOOST.mul(2));
        playerBalance[msg.sender] = playerBalance[msg.sender].add(reward);
        driver = owner;
        lastHijack = now;
        emit JumpedOut(msg.sender, reward);
    }
    
    function tradeMiles() public {
        require(milesDriven[msg.sender] >= MILE_REQ, "not enough miles for reward");
        require(msg.sender != owner, "owner isn't allowed to trade miles");
        require(msg.sender != driver, "can't trade miles while driver");
        
        uint256 milesToTrade = milesDriven[msg.sender].div(MILE_REQ);
        if(milesToTrade > 20) {
            milesToTrade = 20;
        }
        
        uint256 reward = calculateMileReward(milesToTrade);
        loopChest = loopChest.sub(reward);
        milesDriven[msg.sender] = milesDriven[msg.sender].sub(milesToTrade.mul(MILE_REQ));
        playerBalance[msg.sender] = playerBalance[msg.sender].add(reward);
        emit TradedMile(msg.sender, reward, milesToTrade);
    }
    
    function payThrone() public {
        uint256 amount = loopChest;
        loopChest = 0;
        if (!throne.call.value(amount)()) {
            revert();
        }
        emit PaidThrone(msg.sender, amount);
    }
    
    function() public payable {
        loopChest = loopChest.add(msg.value);
        emit BoostedPot(msg.sender, msg.value);
    }
    
    function calculateJumpReward() public view returns(uint256) {
        uint256 timeLeft = raceEndTime.sub(now);
        return DRIVER_TIMER_BOOST.sub(timeLeft).mul(loopChest).div(10000);
    }
    
    function calculateSlugCost(bool buying) public view returns(uint256) {
        if(buying == true) {
            return (SLUG_COST_FLOOR.add(totalSlugs.mul(slugCost).div(ACCEL_FACTOR))).div(loop);
        } else {
            return (SLUG_COST_FLOOR.add(totalSlugs.mul(slugCost).div(ACCEL_FACTOR))).div(loop.add(1));
        }
    }
    
    function calculateSlugBuy(uint256 ethAmount, bool buying) public view returns(uint256) {
        uint256 cost;
        if(buying == true) {
            cost = calculateSlugCost(true);
        } else {
            cost = calculateSlugCost(false);
        }
        return ethAmount.div(cost);
    }
    
    function calculateDividends(address player) public view returns(uint256) {
        uint256 dividends = slugCost.mul(playerSlugs[player]);
        dividends = dividends.sub(playerDividends[player]);
        return dividends;
    }
    
    function computeSpeed(uint256 timestamp) public view returns(uint256) {
        if(raceEndTime > timestamp.add(DRIVER_TIMER_BOOST)) {
            if(raceEndTime.sub(timestamp) < WEEK) {
                return MIN_SPEED.sub((raceEndTime.sub(timestamp).div(DRIVER_TIMER_BOOST)).mul(ACCEL_FACTOR));
            } else {
                return MAX_SPEED;
            }
        } else {
            return MIN_SPEED;
        }
    }
    
    function computeMileDriven() public view returns(uint256) {
        uint256 startSpeed = computeSpeed(lastHijack);
        uint256 endSpeed = computeSpeed(now);
        uint256 timeDriven = now.sub(lastHijack);
        uint256 avgSpeed = (startSpeed.add(endSpeed)).div(2);
        return timeDriven.mul(avgSpeed).div(DRIVER_TIMER_BOOST);
    }
    
    function calculateMileReward(uint256 miles) public view returns(uint256) {
        return miles.mul(loopChest).div(100);
    }
    
    function getSlugCount(address player) public view returns(uint256) {
        return playerSlugs[player];
    }
    
    function getMileCount(address player) public view returns(uint256) {
        return milesDriven[player];
    }
    
    function getBalance(address player) public view returns(uint256) {
        return playerBalance[player];
    }
    
    function claimDividends() private {
        uint256 dividends = calculateDividends(msg.sender);
        if(dividends > 0) {
            playerDividends[msg.sender] = playerDividends[msg.sender].add(dividends);
            playerBalance[msg.sender] = playerBalance[msg.sender].add(dividends);
        }
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