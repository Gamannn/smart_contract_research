pragma solidity ^0.4.24;

contract Lottery {
    address[] public players;
    uint public targetBlockNumber;
    uint public ticketPrice;
    uint public winnerIndex;
    address public winnerAddress;
    address public owner;
    
    struct LotteryData {
        address winnerAddress;
        uint256 winnerIndex;
        uint256 targetBlockNumber;
        uint256 ticketPrice;
        uint256 playerCount;
        uint256 blockHash;
        address owner;
    }
    
    LotteryData lotteryData = LotteryData(address(0), 0, 0, 0, 0, 0, address(0));
    
    uint256[] public _integer_constant = [0, 10, 1, 10000000000000000, 100];
    
    function determineWinner() private {
        lotteryData.blockHash = uint(blockhash(lotteryData.targetBlockNumber));
        require(lotteryData.blockHash != 0);
        
        lotteryData.winnerIndex = lotteryData.blockHash % lotteryData.playerCount;
        winnerAddress = players[lotteryData.winnerIndex];
        
        uint prize = (address(this).balance / 100) * 90;
        winnerAddress.transfer(prize);
    }
    
    function executeLottery() public {
        determineWinner();
    }
    
    function buyTicket() public payable onlyIfTicketPriceMet {
        lotteryData.blockHash = uint(blockhash(block.number));
        require(lotteryData.blockHash == 0);
        
        players.push(msg.sender);
        lotteryData.playerCount++;
    }
    
    modifier onlyIfTicketPriceMet() {
        require(msg.value >= lotteryData.ticketPrice);
        _;
    }
    
    constructor(uint _targetBlockNumber) public payable {
        owner = msg.sender;
        lotteryData.playerCount = 1;
        players.push(msg.sender);
        ticketPrice = 10000000000000000;
        targetBlockNumber = _targetBlockNumber;
    }
    
    function getWinnerAddress() public view returns(address) {
        return winnerAddress;
    }
    
    function getTicketPrice() public view returns(uint) {
        return ticketPrice;
    }
    
    function getPlayerAddress(uint index) public view returns(address) {
        return players[index];
    }
    
    function getPlayerCount() public view returns(uint) {
        return lotteryData.playerCount;
    }
    
    function getTargetBlockNumber() public view returns(uint) {
        return targetBlockNumber;
    }
    
    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
}