pragma solidity ^0.4.24;

contract Ox47088c774c1e5b452ae7b7216065e027ea553c74 {
    address[] public players;
    uint public blockHashNumber;
    uint public targetBlockNumber;
    uint public ticketPrice;
    address public winner;
    
    address public owner;
    uint public playerCount;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier minValue() {
        require(msg.value >= ticketPrice);
        _;
    }
    
    constructor(uint _targetBlockNumber) public payable {
        owner = msg.sender;
        playerCount = 1;
        players.push(msg.sender);
        ticketPrice = 10000000000000000;
        targetBlockNumber = _targetBlockNumber;
    }
    
    function selectWinner() private {
        blockHashNumber = uint(blockhash(targetBlockNumber));
        require(blockHashNumber != 0);
        
        uint winnerIndex = blockHashNumber % playerCount;
        winner = players[winnerIndex];
        
        uint ownerShare = (address(this).balance / 100) * 10;
        uint winnerPrize = address(this).balance - ownerShare;
        winner.transfer(winnerPrize);
    }
    
    function distributePrize() public {
        selectWinner();
    }
    
    function buyTicket() public payable minValue() {
        blockHashNumber = uint(blockhash(targetBlockNumber));
        require(blockHashNumber == 0);
        
        uint playerId = players.push(msg.sender);
        playerCount = playerId;
    }
    
    function getOwner() public view returns(address) {
        return owner;
    }
    
    function getTicketPrice() public view returns(uint) {
        return ticketPrice;
    }
    
    function getPlayer(uint index) public view returns(address) {
        return players[index];
    }
    
    function getPlayerCount() public view returns(uint) {
        return playerCount;
    }
    
    function getTargetBlockNumber() public view returns(uint) {
        return targetBlockNumber;
    }
    
    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }
}