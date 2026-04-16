```solidity
pragma solidity ^0.4.24;

contract SnailFarm {
    using SafeMath for uint256;
    
    event SoldAcorn(address indexed seller, uint256 acorns, uint256 eth);
    event BoughtAcorn(address indexed buyer, uint256 acorns, uint256 eth);
    event BecameMaster(address indexed player, uint256 indexed round, uint256 reward, uint256 pot);
    event WithdrewEarnings(address indexed player, uint256 eth);
    event Hatched(address indexed player, uint256 eggs, uint256 hatched);
    event SoldEgg(address indexed seller, uint256 eggs, uint256 eth);
    event BoughtEgg(address indexed buyer, uint256 eggs, uint256 eth);
    event StartedSnailing(address indexed player, uint256 indexed round);
    event BecameQueen(address indexed player, uint256 indexed round, uint256 price);
    event BecameDuke(address indexed player, uint256 indexed round, uint256 price);
    event BecamePrince(address indexed player, uint256 indexed round, uint256 price);
    
    uint256 public TIME_TO_HATCH_1SNAIL = 86400;
    
    bool public gameStarted;
    address public gameOwner;
    
    mapping(address => uint256) public hatcherySnail;
    mapping(address => uint256) public lastHatch;
    mapping(address => uint256) public playerAcorns;
    mapping(address => uint256) public playerEarnings;
    mapping(address => uint256) public playerProdBoost;
    
    mapping(address => bool) public startingSnails;
    
    uint256 public totalAcorns;
    uint256 public treePot;
    uint256 public snailPot;
    uint256 public marketEggs;
    
    uint256 public round;
    
    address public currentSpiderOwner;
    uint256 public SPIDER_BASE_REQ;
    uint256 public SPIDER_BOOST;
    
    address public currentSquirrelOwner;
    uint256 public SQUIRREL_BASE_REQ;
    uint256 public SQUIRREL_BOOST;
    
    address public currentTadpoleOwner;
    uint256 public TADPOLE_BASE_REQ;
    uint256 public TADPOLE_BOOST;
    
    uint256 public STARTING_SNAIL_COST;
    uint256 public STARTING_SNAIL_AMOUNT;
    uint256 public HATCHING_COST;
    
    constructor() public {
        gameOwner = msg.sender;
        currentSpiderOwner = gameOwner;
        startingSnails[gameOwner] = true;
        playerProdBoost[gameOwner] = 4;
        
        TIME_TO_HATCH_1SNAIL = 86400;
        SPIDER_BASE_REQ = 10;
        SPIDER_BOOST = 2;
        SQUIRREL_BASE_REQ = 200;
        SQUIRREL_BOOST = 2;
        TADPOLE_BASE_REQ = 100000;
        TADPOLE_BOOST = 12;
        STARTING_SNAIL_COST = 800000000000000;
        STARTING_SNAIL_AMOUNT = 100;
        HATCHING_COST = 4000000000000000;
        
        round = 1;
        gameStarted = true;
    }
    
    function sellAcorns(uint256 _acorns) public {
        require(playerAcorns[msg.sender] >= _acorns);
        
        playerAcorns[msg.sender] = playerAcorns[msg.sender].sub(_acorns);
        uint256 eth = computeAcornPrice().mul(_acorns);
        totalAcorns = totalAcorns.sub(_acorns);
        treePot = treePot.add(eth);
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(eth);
        
        emit SoldAcorn(msg.sender, _acorns, eth);
    }
    
    function buyAcorns() public payable {
        require(msg.value > 0);
        require(tx.origin == msg.sender);
        require(gameStarted);
        
        uint256 acornsBought;
        if (snailPot < treePot) {
            acornsBought = (msg.value.mul(computeAcornPrice())).div(3).div(4);
            fundTreePot(msg.value);
        } else {
            acornsBought = msg.value.mul(computeAcornPrice()).div(2);
            fundSnailPot(msg.value);
        }
        
        totalAcorns = totalAcorns.add(acornsBought);
        playerAcorns[msg.sender] = playerAcorns[msg.sender].add(acornsBought);
        
        emit BoughtAcorn(msg.sender, acornsBought, msg.value);
    }
    
    function becomeSnailmaster() public {
        require(gameStarted);
        require(hatcherySnail[msg.sender] >= SPIDER_BASE_REQ);
        
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].sub(10);
        
        uint256 snailReqIncrease = round.mul(SPIDER_BASE_REQ).div(100);
        uint256 startSnailIncrease = round.mul(STARTING_SNAIL_AMOUNT).div(100);
        
        SPIDER_BASE_REQ = SPIDER_BASE_REQ.add(snailReqIncrease);
        STARTING_SNAIL_AMOUNT = STARTING_SNAIL_AMOUNT.add(startSnailIncrease);
        
        uint256 previousSnailPot = snailPot;
        uint256 reward = snailPot.div(5);
        snailPot = snailPot.sub(reward);
        round++;
        
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(reward);
        
        emit BecameMaster(msg.sender, round, reward, snailPot);
    }
    
    function withdrawEarnings() public {
        require(playerEarnings[msg.sender] > 0);
        uint256 eth = playerEarnings[msg.sender];
        playerEarnings[msg.sender] = 0;
        msg.sender.transfer(eth);
        emit WithdrewEarnings(msg.sender, eth);
    }
    
    function fundSnailPot(uint256 _value) private {
        uint256 snailShare = _value.div(2);
        snailPot = snailPot.add(snailShare);
        treePot = treePot.add(snailShare);
    }
    
    function fundTreePot(uint256 _value) private {
        uint256 treeShare = _value.div(4);
        uint256 snailShare = _value.sub(treeShare);
        treePot = treePot.add(treeShare);
        snailPot = snailPot.add(snailShare);
    }
    
    function hatchEggs() public payable {
        require(gameStarted);
        require(msg.value == HATCHING_COST);
        
        fundSnailPot(msg.value);
        uint256 eggs = getMyEggs();
        uint256 hatched = (eggs.mul(TIME_TO_HATCH_1SNAIL)).div(hatcherySnail[msg.sender]);
        
        hatcherySnail[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].add(hatched);
        
        emit Hatched(msg.sender, eggs, hatched);
    }
    
    function sellEggs() public {
        require(gameStarted);
        uint256 eggs = getMyEggs();
        uint256 eth = calculateEggSell(eggs);
        
        hatcherySnail[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = marketEggs.add(eggs);
        snailPot = snailPot.sub(eth);
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(eth);
        
        emit SoldEgg(msg.sender, eggs, eth);
    }
    
    function buyEggs() public payable {
        require(gameStarted);
        require(startingSnails[msg.sender] == true);
        require(msg.sender != gameOwner);
        
        uint256 eggsBought = calculateEggBuy(msg.value);
        fundSnailPot(msg.value);
        marketEggs = marketEggs.sub(eggsBought);
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].add(eggsBought);
        
        emit BoughtEgg(msg.sender, eggsBought, msg.value);
    }
    
    function startSnailing() public payable {
        require(gameStarted);
        require(tx.origin == msg.sender);
        require(startingSnails[msg.sender] == false);
        require(msg.value == STARTING_SNAIL_COST);
        
        fundSnailPot(msg.value);
        startingSnails[msg.sender] = true;
        lastHatch[msg.sender] = now;
        playerProdBoost[msg.sender] = 1;
        hatcherySnail[msg.sender] = STARTING_SNAIL_AMOUNT;
        
        emit StartedSnailing(msg.sender, round);
    }
    
    function becomeSpider() public {
        require(gameStarted);
        require(startingSnails[msg.sender] == true);
        require(hatcherySnail[msg.sender] >= SPIDER_BASE_REQ);
        
        playerProdBoost[currentSpiderOwner] = playerProdBoost[currentSpiderOwner].sub(SPIDER_BOOST);
        currentSpiderOwner = msg.sender;
        playerProdBoost[currentSpiderOwner] = playerProdBoost[currentSpiderOwner].add(SPIDER_BOOST);
        
        emit BecameQueen(msg.sender, round, SPIDER_BASE_REQ);
    }
    
    function becomeSquirrel() public {
        require(gameStarted);
        require(startingSnails[msg.sender] == true);
        require(playerAcorns[msg.sender] >= SQUIRREL_BASE_REQ);
        
        playerAcorns[msg.sender] = playerAcorns[msg.sender].sub(SQUIRREL_BASE_REQ);
        totalAcorns = totalAcorns.sub(SQUIRREL_BASE_REQ);
        
        playerProdBoost[currentSquirrelOwner] = playerProdBoost[currentSquirrelOwner].sub(SQUIRREL_BOOST);
        currentSquirrelOwner = msg.sender;
        playerProdBoost[currentSquirrelOwner] = playerProdBoost[currentSquirrelOwner].add(SQUIRREL_BOOST);
        
        emit BecameDuke(msg.sender, round, SQUIRREL_BASE_REQ);
    }
    
    function becomeTadpole() public payable {
        require(gameStarted);
        require(startingSnails[msg.sender] == true);
        require(msg.value >= TADPOLE_BASE_REQ);
        
        if (msg.value > TADPOLE_BASE_REQ) {
            uint256 excess = msg.value.sub(TADPOLE_BASE_REQ);
            playerEarnings[msg.sender] = playerEarnings[msg.sender].add(excess);
        }
        
        uint256 tadpolePrice = TADPOLE_BASE_REQ.mul(12).div(10);
        fundSnailPot(TADPOLE_BASE_REQ);
        
        playerEarnings[currentTadpoleOwner] = playerEarnings[currentTadpoleOwner].add(tadpolePrice.div(6));
        playerProdBoost[currentTadpoleOwner] = playerProdBoost[currentTadpoleOwner].sub(TADPOLE_BOOST);
        
        currentTadpoleOwner = msg.sender;
        playerProdBoost[currentTadpoleOwner] = playerProdBoost[currentTadpoleOwner].add(TADPOLE_BOOST);
        
        emit BecamePrince(msg.sender, round, TADPOLE_BASE_REQ);
    }
    
    function computeAcornPrice() public view returns(uint256) {
        return treePot.div(totalAcorns);
    }
    
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        uint256 eggValue = calculateEggValue(eggs);
        uint256 marketValue = eggs.mul(snailPot).div(marketEggs.add(eggs));
        return marketValue.div(2);
    }
    
    function calculateEggBuy(uint256 eth) public view returns(uint256) {
        uint256 eggValue = eth.add(snailPot);
        uint256 eggsBought = eth.mul(marketEggs).div(eggValue).mul(eth);
        return eggsBought;
    }
    
    function getMyEggs() public view returns(uint256) {
        return hatcherySnail[msg.sender].add(eggsSinceLastHatch(msg.sender));
    }
    
    function eggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(TIME_TO_HATCH_1SNAIL, now.sub(lastHatch[adr]));
        return secondsPassed.mul(hatcherySnail[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns(uint256) {
        return a < b ? a : b;
    }
    
    function getMySnails() public view returns(uint256) {
        return hatcherySnail[msg.sender];
    }
    
    function getMyProdBoost() public view returns(uint256) {
        return playerProdBoost[msg.sender];
    }
    
    function getMyEggsForHatching() public view returns(uint256) {
        return getMyEggs().div(TIME_TO_HATCH_1SNAIL);
    }
    
    function getMyAcorns() public view returns(uint256) {
        return playerAcorns[msg.sender];
    }
    
    function getMyEarnings() public view returns(uint256) {
        return playerEarnings[msg.sender];
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
```