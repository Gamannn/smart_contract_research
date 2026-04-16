```solidity
pragma solidity ^0.4.24;

contract AcornGame {
    using SafeMath for uint;

    event SoldAcorn(address indexed seller, uint acornAmount, uint ethAmount);
    event BoughtAcorn(address indexed buyer, uint acornAmount, uint ethAmount);
    event BecameMaster(address indexed master, uint indexed round, uint reward, uint snailPot);
    event WithdrewEarnings(address indexed player, uint ethAmount);
    event Hatched(address indexed player, uint eggAmount, uint hatchAmount);
    event SoldEgg(address indexed seller, uint eggAmount, uint ethAmount);
    event BoughtEgg(address indexed buyer, uint eggAmount, uint ethAmount);
    event StartedSnailing(address indexed player, uint indexed round);
    event BecameQueen(address indexed queen, uint indexed round, uint reward);
    event BecameDuke(address indexed duke, uint indexed round, uint reward);
    event BecamePrince(address indexed prince, uint indexed round, uint reward);

    uint256 public TIME_TO_HATCH_1SNAIL = 86400;
    address public gameOwner;
    address public currentSpiderOwner;
    address public currentSquirrelOwner;
    address public currentTadpoleOwner;
    uint256 public snailPot;
    uint256 public totalAcorns;
    uint256 public round;
    bool public gameStarted;

    mapping(address => uint256) public playerAcorns;
    mapping(address => uint256) public playerEggs;
    mapping(address => uint256) public playerEarnings;
    mapping(address => uint256) public playerSnails;
    mapping(address => uint256) public playerProdBoost;
    mapping(address => bool) public hasStartedSnailing;

    constructor() public {
        gameOwner = msg.sender;
        currentSpiderOwner = msg.sender;
        hasStartedSnailing[msg.sender] = true;
        playerProdBoost[msg.sender] = 4;
    }

    function startRound(uint256 eggAmount, uint256 snailAmount) public payable {
        require(msg.value > 0);
        require(snailPot == 0);
        require(msg.sender == gameOwner);

        uint256 acornAmount = msg.value.div(TIME_TO_HATCH_1SNAIL);
        totalAcorns = totalAcorns.add(acornAmount);
        playerAcorns[msg.sender] = playerAcorns[msg.sender].add(acornAmount);

        snailPot = snailPot.add(msg.value.div(5));
        round = round.add(1);
        gameStarted = true;
    }

    function sellAcorns(uint256 acornAmount) public {
        require(playerAcorns[msg.sender] > 0);

        uint256 ethAmount = acornAmount.div(100);
        playerAcorns[msg.sender] = playerAcorns[msg.sender].sub(acornAmount);
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(ethAmount);

        emit SoldAcorn(msg.sender, acornAmount, ethAmount);
    }

    function buyAcorns() public payable {
        require(msg.value > 0);
        require(tx.origin == msg.sender);

        uint256 acornAmount;
        if (totalAcorns < playerAcorns[msg.sender]) {
            acornAmount = msg.value.div(3).mul(4);
        } else {
            acornAmount = msg.value.div(2);
        }

        totalAcorns = totalAcorns.add(acornAmount);
        playerAcorns[msg.sender] = playerAcorns[msg.sender].add(acornAmount);

        emit BoughtAcorn(msg.sender, acornAmount, msg.value);
    }

    function becomeMaster() public {
        require(gameStarted);
        require(playerSnails[msg.sender] >= 10);

        uint256 reward = snailPot.div(5);
        snailPot = snailPot.sub(reward);
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(reward);

        round = round.add(1);
        emit BecameMaster(msg.sender, round, reward, snailPot);
    }

    function withdrawEarnings() public {
        require(playerEarnings[msg.sender] > 0);

        uint256 earnings = playerEarnings[msg.sender];
        playerEarnings[msg.sender] = 0;
        msg.sender.transfer(earnings);

        emit WithdrewEarnings(msg.sender, earnings);
    }

    function hatchEggs() public payable {
        require(gameStarted);
        require(msg.value == 0.02 ether);

        uint256 hatchAmount = playerEggs[msg.sender].div(TIME_TO_HATCH_1SNAIL);
        playerEggs[msg.sender] = playerEggs[msg.sender].sub(hatchAmount);
        playerSnails[msg.sender] = playerSnails[msg.sender].add(hatchAmount);

        emit Hatched(msg.sender, playerEggs[msg.sender], hatchAmount);
    }

    function buyEggs() public payable {
        require(gameStarted);
        require(hasStartedSnailing[msg.sender] == true);
        require(msg.sender != gameOwner);

        uint256 eggAmount = msg.value.div(0.01 ether);
        playerEggs[msg.sender] = playerEggs[msg.sender].add(eggAmount);

        emit BoughtEgg(msg.sender, eggAmount, msg.value);
    }

    function startSnailing() public payable {
        require(gameStarted);
        require(tx.origin == msg.sender);
        require(hasStartedSnailing[msg.sender] == false);
        require(msg.value == 0.008 ether);

        hasStartedSnailing[msg.sender] = true;
        playerProdBoost[msg.sender] = 1;
        playerSnails[msg.sender] = 1;

        emit StartedSnailing(msg.sender, round);
    }

    function becomeQueen() public {
        require(gameStarted);
        require(playerSnails[msg.sender] >= 10);

        playerProdBoost[currentSpiderOwner] = playerProdBoost[currentSpiderOwner].sub(10);
        currentSpiderOwner = msg.sender;
        playerProdBoost[currentSpiderOwner] = playerProdBoost[currentSpiderOwner].add(10);

        emit BecameQueen(msg.sender, round, 10);
    }

    function becomeDuke() public payable {
        require(gameStarted);
        require(hasStartedSnailing[msg.sender] == true);
        require(msg.value >= 0.01 ether);

        if (msg.value > 0.01 ether) {
            uint256 excess = msg.value.sub(0.01 ether);
            playerEarnings[msg.sender] = playerEarnings[msg.sender].add(excess);
        }

        playerProdBoost[currentSquirrelOwner] = playerProdBoost[currentSquirrelOwner].sub(10);
        currentSquirrelOwner = msg.sender;
        playerProdBoost[currentSquirrelOwner] = playerProdBoost[currentSquirrelOwner].add(10);

        emit BecameDuke(msg.sender, round, 10);
    }

    function becomePrince() public payable {
        require(gameStarted);
        require(hasStartedSnailing[msg.sender] == true);
        require(msg.value >= 0.01 ether);

        if (msg.value > 0.01 ether) {
            uint256 excess = msg.value.sub(0.01 ether);
            playerEarnings[msg.sender] = playerEarnings[msg.sender].add(excess);
        }

        playerProdBoost[currentTadpoleOwner] = playerProdBoost[currentTadpoleOwner].sub(10);
        currentTadpoleOwner = msg.sender;
        playerProdBoost[currentTadpoleOwner] = playerProdBoost[currentTadpoleOwner].add(10);

        emit BecamePrince(msg.sender, round, 10);
    }

    function computeAcornProduction() public view returns (uint256) {
        return totalAcorns.div(playerAcorns[msg.sender]);
    }

    function getPlayerAcorns() public view returns (uint256) {
        return playerAcorns[msg.sender];
    }

    function getPlayerEggs() public view returns (uint256) {
        return playerEggs[msg.sender];
    }

    function getPlayerEarnings() public view returns (uint256) {
        return playerEarnings[msg.sender];
    }

    function getPlayerSnails() public view returns (uint256) {
        return playerSnails[msg.sender];
    }

    function getPlayerProdBoost() public view returns (uint256) {
        return playerProdBoost[msg.sender];
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