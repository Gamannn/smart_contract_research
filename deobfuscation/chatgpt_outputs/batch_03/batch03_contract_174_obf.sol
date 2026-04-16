```solidity
pragma solidity ^0.4.21;

contract Lottery {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping(address => uint) private playerRounds;
    mapping(address => uint) private playerStatus;
    mapping(uint => address) private roundPlayers;

    struct LotteryState {
        address lastWinner;
        address owner;
        address contractAddress;
        uint256 currentRound;
        uint256 lastBlockNumber;
        uint256 prizePool;
        uint256 playersCount;
        uint256 ticketPrice;
        uint256 maxPlayers;
    }

    LotteryState private lotteryState;

    function Lottery() public {
        lotteryState.contractAddress = this;
        lotteryState.currentRound++;
        lotteryState.maxPlayers = 25;
        lotteryState.owner = msg.sender;
        lotteryState.ticketPrice = 0.005 ether;
        lotteryState.lastWinner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == lotteryState.owner);
        _;
    }

    modifier noActivePlayers() {
        require(lotteryState.playersCount == 0);
        require(lotteryState.contractAddress.balance == 0 ether);
        _;
    }

    modifier validEntry() {
        require(playerRounds[msg.sender] < lotteryState.currentRound);
        require(lotteryState.playersCount < lotteryState.maxPlayers);
        require(msg.value == lotteryState.ticketPrice);
        require(playerStatus[msg.sender] == 0);
        _;
    }

    modifier canDraw() {
        require(lotteryState.playersCount == lotteryState.maxPlayers);
        require(block.blockhash(lotteryState.lastBlockNumber) != 0);
        _;
    }

    modifier isWinner() {
        require(playerStatus[msg.sender] == 1);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(lotteryState.owner, newOwner);
        lotteryState.owner = newOwner;
    }

    function setTicketPrice(uint newPrice) external noActivePlayers onlyOwner {
        lotteryState.ticketPrice = newPrice;
    }

    function getLotteryInfo() view public returns (uint, uint, address) {
        uint canEnter = 0;
        uint playersCount = lotteryState.playersCount;
        address lastWinner = lotteryState.lastWinner;
        if (playerRounds[msg.sender] < lotteryState.currentRound) {
            canEnter = 1;
        }
        return (canEnter, playersCount, lastWinner);
    }

    function enterLottery() payable public validEntry {
        lotteryState.playersCount++;
        playerRounds[msg.sender] = lotteryState.currentRound;
        roundPlayers[lotteryState.playersCount] = msg.sender;
        if (lotteryState.playersCount == lotteryState.maxPlayers) {
            lotteryState.lastBlockNumber = block.number;
        }
    }

    function drawWinner() external canDraw {
        uint currentBlock = block.number;
        if (currentBlock - lotteryState.lastBlockNumber <= 255) {
            lotteryState.playersCount = 0;
            lotteryState.currentRound++;
            uint winningIndex = uint(block.blockhash(lotteryState.lastBlockNumber)) % lotteryState.maxPlayers + 1;
            address winner = roundPlayers[winningIndex];
            playerStatus[winner] = 1;
            lotteryState.lastWinner = winner;
            msg.sender.transfer(lotteryState.ticketPrice);
        } else {
            lotteryState.lastBlockNumber = block.number;
        }
    }

    function claimPrize() external isWinner {
        playerStatus[msg.sender] = 0;
        lotteryState.prizePool = (lotteryState.ticketPrice * (lotteryState.maxPlayers - 1));
        msg.sender.transfer(lotteryState.prizePool);
    }
}
```