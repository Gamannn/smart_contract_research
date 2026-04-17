pragma solidity ^0.4.21;

contract Lottery {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    mapping (address => uint) private playerNumber;
    mapping (address => uint) public playerCount;
    mapping (address => uint) public maxPlayers;
    mapping (address => uint) public winningNumber;
    mapping (address => uint) private playerGame;
    mapping (address => uint) private playerHash;
    mapping (uint => address) private numberToPlayer;
    
    uint public currentBet;
    address public contractAddress;
    address public owner;
    address public lastWinner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    modifier gameExists() {
        require(playerCount[contractAddress] == 0);
        _;
    }
    
    function setCurrentBet(uint betAmount) public gameExists onlyOwner {
        currentBet = betAmount;
    }
    
    function startNewGame() public {
        contractAddress = this;
        playerCount[contractAddress]++;
        maxPlayers[contractAddress] = 100;
        owner = msg.sender;
        currentBet = 0.005 ether;
        lastWinner = address(0);
    }
    
    function getGameStatus() view public returns (uint, uint, address) {
        uint status = 0;
        uint count = playerCount[contractAddress];
        address winner = lastWinner;
        
        if (playerGame[msg.sender] == playerCount[contractAddress]) {
            status = 1;
        }
        
        return (status, count, winner);
    }
    
    modifier validBet(uint number) {
        require(playerGame[msg.sender] < playerCount[contractAddress]);
        require(playerCount[contractAddress] < maxPlayers[contractAddress]);
        require(msg.value == currentBet);
        require(number > 0 && number != 0);
        _;
    }
    
    function placeBet(uint number) payable validBet(number) {
        playerHash[msg.sender] = 0;
        playerCount[contractAddress]++;
        playerGame[msg.sender] = playerCount[contractAddress];
        
        uint hashValue = uint(keccak256(number + now + contractAddress));
        playerNumber[contractAddress] += hashValue;
        playerHash[msg.sender] = playerCount[contractAddress];
        numberToPlayer[playerHash[msg.sender]] = msg.sender;
        
        if (playerCount[contractAddress] == maxPlayers[contractAddress]) {
            playerCount[contractAddress]++;
            winningNumber[contractAddress] = uint(keccak256(now + contractAddress + playerNumber[contractAddress])) % 100 + 1;
            address winner = numberToPlayer[winningNumber[contractAddress]];
            winner.transfer(currentBet * 99);
            owner.transfer(currentBet * 1);
            lastWinner = winner;
            playerCount[contractAddress] = 0;
            playerNumber[contractAddress] = 0;
        }
    }
    
    function getIntFunc(uint256 index) internal returns(uint256) {
        return _integer_constant[index];
    }
    
    uint256[] public _integer_constant = [99, 100, 1, 5000000000000000, 0];
}