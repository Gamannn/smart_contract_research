pragma solidity ^0.4.21;

contract Lottery {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    mapping (address => uint) private participantRound;
    mapping (address => uint) private winnerStatus;
    mapping (uint => address) private participantIndex;
    
    struct GameState {
        address lastWinner;
        address owner;
        address contractAddress;
        uint256 currentRound;
        uint256 targetBlock;
        uint256 prizePool;
        uint256 participantCount;
        uint256 entryFee;
        uint256 maxParticipants;
    }
    
    GameState private state;
    
    function Lottery() public {
        state.contractAddress = this;
        state.currentRound++;
        state.maxParticipants = 25;
        state.owner = msg.sender;
        state.entryFee = 0.005 ether;
        state.lastWinner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == state.owner);
        _;
    }
    
    modifier onlyWhenNotStarted() {
        require(state.participantCount == 0);
        require(state.contractAddress.balance == 0 ether);
        _;
    }
    
    modifier canParticipate() {
        require(participantRound[msg.sender] < state.currentRound);
        require(state.participantCount < state.maxParticipants);
        require(msg.value == state.entryFee);
        require(winnerStatus[msg.sender] == 0);
        _;
    }
    
    modifier canDrawWinner() {
        require(state.participantCount == state.maxParticipants);
        require(block.blockhash(state.targetBlock) != 0);
        _;
    }
    
    modifier onlyWinner() {
        require(winnerStatus[msg.sender] == 1);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(state.owner, newOwner);
        state.owner = newOwner;
    }
    
    function setEntryFee(uint fee) external onlyWhenNotStarted onlyOwner {
        state.entryFee = fee;
    }
    
    function getPlayerInfo() view public returns (uint, uint, address) {
        uint canPlay = 0;
        uint currentCount = state.participantCount;
        address lastWinner = state.lastWinner;
        
        if (participantRound[msg.sender] < state.currentRound) {
            canPlay = 1;
        }
        
        return (canPlay, currentCount, lastWinner);
    }
    
    function participate() payable public canParticipate {
        state.participantCount++;
        participantRound[msg.sender] = state.currentRound;
        participantIndex[state.participantCount] = msg.sender;
        
        if (state.participantCount == state.maxParticipants) {
            state.targetBlock = block.number;
        }
    }
    
    function drawWinner() external canDrawWinner {
        uint currentBlock = block.number;
        
        if (currentBlock - state.targetBlock <= 255) {
            state.participantCount = 0;
            state.currentRound++;
            
            uint winnerIndex = uint(block.blockhash(state.targetBlock)) % state.maxParticipants + 1;
            address winner = participantIndex[winnerIndex];
            
            winnerStatus[winner] = 1;
            state.lastWinner = winner;
            
            msg.sender.transfer(state.entryFee);
        } else {
            state.targetBlock = block.number;
        }
    }
    
    function claimPrize() external onlyWinner {
        winnerStatus[msg.sender] = 0;
        state.prizePool = (state.entryFee * (state.maxParticipants - 1));
        msg.sender.transfer(state.prizePool);
    }
}