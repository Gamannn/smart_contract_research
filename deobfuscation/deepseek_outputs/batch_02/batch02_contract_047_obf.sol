```solidity
pragma solidity ^0.4.24;

contract SnailFarm {
    using SafeMath for uint256;
    
    event WithdrewEarnings(address indexed player, uint256 amount);
    event ClaimedDivs(address indexed player, uint256 amount);
    event BoughtSnail(address indexed player, uint256 ethSpent, uint256 snailsBought);
    event SoldSnail(address indexed player, uint256 ethReceived, uint256 snailsSold);
    event HatchedSnail(address indexed player, uint256 ethSpent, uint256 snailsHatched);
    event FedFrogking(address indexed player, uint256 ethSpent, uint256 frogsFed);
    event Ascended(address indexed player, uint256 reward, uint256 indexed round);
    event BecamePharaoh(address indexed player, uint256 indexed round);
    event NewDivs(uint256 amount);
    
    uint256 public SECONDS_IN_DAY = 86400;
    uint256 public GOD_TIMER_START = 480;
    uint256 public GOD_TIMER_BOOST = 8;
    uint256 public PHARAOH_REQ_START = 300;
    uint256 public TOKEN_MAX_BUY = 4000000000000000000;
    uint256 public MAX_SNAIL = 10000000;
    
    address public owner;
    address public god;
    uint256 public godTimer;
    uint256 public round;
    bool public gameStarted;
    uint256 public contractStartTime;
    
    uint256 public snailPot;
    uint256 public frogPot;
    uint256 public godPot;
    
    uint256 public totalSnails;
    uint256 public divsPerSnail;
    
    mapping(address => uint256) public playerSnails;
    mapping(address => uint256) public claimedDivs;
    mapping(address => uint256) public playerEarnings;
    mapping(address => uint256) public lastClaim;
    
    constructor() public {
        owner = msg.sender;
        godTimer = now + SECONDS_IN_DAY;
        round = 1;
        gameStarted = true;
        god = owner;
        contractStartTime = now;
        initializePlayer(msg.sender);
    }
    
    function withdrawEarnings() public {
        require(playerEarnings[msg.sender] > 0);
        uint256 amount = playerEarnings[msg.sender];
        playerEarnings[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit WithdrewEarnings(msg.sender, amount);
    }
    
    function claimDivs() public {
        uint256 divs = calculateMyDivs();
        if(divs > 0) {
            claimedDivs[msg.sender] = claimedDivs[msg.sender].add(divs);
            playerEarnings[msg.sender] = playerEarnings[msg.sender].add(divs);
            emit ClaimedDivs(msg.sender, divs);
        }
    }
    
    function buySnail(address ref) public payable {
        require(gameStarted == true, "game hasn't started yet");
        require(tx.origin == msg.sender, "contracts not allowed");
        require(msg.value <= TOKEN_MAX_BUY, "maximum buy = 4 ETH");
        
        uint256 snailsBought = calculateBuy(msg.value);
        totalSnails = totalSnails.add(snailsBought);
        
        distributeFunds(msg.value, ref, true);
        
        lastClaim[msg.sender] = now;
        playerSnails[msg.sender] = playerSnails[msg.sender].add(snailsBought);
        
        emit BoughtSnail(msg.sender, msg.value, snailsBought);
    }
    
    function sellSnail(uint256 snailsToSell) public {
        require(gameStarted == true, "game hasn't started yet");
        require(playerSnails[msg.sender] >= snailsToSell, "not enough snails to sell");
        
        claimDivs();
        
        uint256 sellPrice = calculateSell(snailsToSell);
        uint256 fee = sellPrice.div(10);
        uint256 maxEth = address(this).balance.div(2);
        uint256 maxTokens = playerSnails[msg.sender];
        
        if(snailsToSell > maxTokens) {
            snailsToSell = maxTokens;
        }
        
        uint256 ethReceived = snailsToSell.mul(sellPrice);
        
        snailPot = snailPot.sub(snailsToSell);
        playerSnails[msg.sender] = playerSnails[msg.sender].sub(snailsToSell);
        totalSnails = totalSnails.sub(snailsToSell);
        divsPerSnail = divsPerSnail.add(snailsToSell);
        claimedDivs[msg.sender] = claimedDivs[msg.sender].sub(divsPerSnail.mul(snailsToSell));
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(ethReceived);
        
        emit SoldSnail(msg.sender, ethReceived, snailsToSell);
    }
    
    function hatchEggs() public payable {
        require(gameStarted == true, "game hasn't started yet");
        require(msg.value > 0, "need ETH to hatch eggs");
        
        uint256 tokenPrice = calculateTokenPrice().div(2);
        uint256 eggsToHatch = msg.value.div(tokenPrice);
        uint256 myEggs = calculateMyEggs(msg.sender);
        uint256 ethRequired = tokenPrice.mul(myEggs);
        uint256 ethSpent = msg.value;
        
        if (msg.value > ethRequired) {
            uint256 refund = msg.value.sub(ethRequired);
            playerEarnings[msg.sender] = playerEarnings[msg.sender].add(refund);
            ethSpent = ethRequired;
        }
        
        if (msg.value < ethRequired) {
            eggsToHatch = msg.value.div(tokenPrice);
        }
        
        claimedDivs[msg.sender] = claimedDivs[msg.sender].add(eggsToHatch.mul(divsPerSnail));
        totalSnails = totalSnails.add(eggsToHatch);
        distributeFunds(ethSpent, msg.sender, false);
        lastClaim[msg.sender] = now;
        playerSnails[msg.sender] = playerSnails[msg.sender].add(eggsToHatch);
        
        emit HatchedSnail(msg.sender, ethSpent, eggsToHatch);
    }
    
    function distributeFunds(uint256 eth, address ref, bool isBuy) private {
        uint256 fee = eth.div(2);
        
        if (isBuy == true) {
            snailPot = snailPot.add(fee);
            divsPerSnail = divsPerSnail.add(eth.div(5).div(totalSnails));
        }
        
        frogPot = frogPot.add(eth.div(5).div(5).div(totalSnails));
        godPot = godPot.add(eth.div(5).div(5).div(totalSnails));
        
        owner.transfer(fee.div(2).div(50));
        playerEarnings[owner] = playerEarnings[owner].add(fee.div(2).div(50));
        godPot = godPot.add(fee.div(2).div(50));
        
        if (ref != msg.sender && playerSnails[ref] >= 20000000000000) {
            playerEarnings[ref] = playerEarnings[ref].add(fee.div(6).div(50));
        } else {
            frogPot = frogPot.add(fee.div(6).div(50));
        }
    }
    
    function feedFrogking() public {
        require(gameStarted == true, "game hasn't started yet");
        require(totalSnails > 0);
        
        uint256 myEggs = calculateMyEggs(msg.sender);
        lastClaim[msg.sender] = now;
        
        uint256 frogsFed = frogPot.div(totalSnails);
        frogPot = frogPot.sub(frogsFed);
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(frogsFed);
        
        emit FedFrogking(msg.sender, frogsFed, frogsFed);
    }
    
    function ascendGod() public {
        require(gameStarted == true, "game hasn't started yet");
        require(now >= godTimer, "god hasn't ascended yet");
        
        godTimer = now + GOD_TIMER_START;
        god = msg.sender;
        round = round.add(1);
        
        uint256 reward = godPot.div(2);
        godPot = godPot.sub(reward);
        playerEarnings[god] = playerEarnings[god].add(reward);
        
        emit Ascended(god, reward, round);
        god = msg.sender;
    }
    
    function becomePharaoh(uint256 snails) public {
        require(gameStarted == true, "game hasn't started yet");
        require(playerSnails[msg.sender] >= snails, "not enough snails in hatchery");
        
        if(now >= godTimer) {
            ascendGod();
        }
        
        claimDivs();
        
        uint256 pharaohReq = PHARAOH_REQ_START;
        if(pharaohReq < GOD_TIMER_START){
            pharaohReq = GOD_TIMER_START;
        } else {
            pharaohReq = totalSnails.mul(snails);
            if(pharaohReq < PHARAOH_REQ_START){
                pharaohReq = PHARAOH_REQ_START;
            }
        }
        
        if(snails >= pharaohReq) {
            totalSnails = totalSnails.sub(snails);
            playerSnails[msg.sender] = playerSnails[msg.sender].sub(snails);
            claimedDivs[msg.sender] = claimedDivs[msg.sender].sub(snails.mul(divsPerSnail));
            godTimer = godTimer.add(GOD_TIMER_BOOST);
            pharaohReq = snails.add(PHARAOH_REQ_START);
            god = msg.sender;
            emit BecamePharaoh(msg.sender, round);
        }
    }
    
    function() public payable {
        divsPerSnail = divsPerSnail.add(msg.value.div(totalSnails));
        emit NewDivs(msg.value);
    }
    
    function calculateTokenPrice() public view returns(uint256) {
        uint256 secondsPassed = now.sub(contractStartTime);
        uint256 priceIncrease = secondsPassed.div(1080000);
        return 20000000000000 + priceIncrease;
    }
    
    function calculateBuy(uint256 eth) public view returns(uint256) {
        uint256 tokenPrice = calculateTokenPrice();
        return eth.div(tokenPrice);
    }
    
    function calculateSell(uint256 snails) public view returns(uint256) {
        uint256 tokenPrice = calculateTokenPrice();
        return snails.mul(tokenPrice);
    }
    
    function calculateMyEggs(address player) public view returns(uint256) {
        uint256 secondsPassed = now.sub(lastClaim[player]);
        secondsPassed = secondsPassed.mul(playerSnails[player]).div(1 days);
        if (secondsPassed > playerSnails[player]) {
            secondsPassed = playerSnails[player];
        }
        return secondsPassed;
    }
    
    function calculateMyDivs() public view returns(uint256) {
        uint256 divs = divsPerSnail.mul(playerSnails[msg.sender]);
        divs = divs.sub(claimedDivs[msg.sender]);
        return divs;
    }
    
    function mySnails() public view returns(uint256) {
        return playerSnails[msg.sender];
    }
    
    function myEarnings() public view returns(uint256) {
        return playerEarnings[msg.sender];
    }
    
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function initializePlayer(address player) private {
        playerSnails[player] = 1;
        lastClaim[player] = now;
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