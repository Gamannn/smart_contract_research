pragma solidity ^0.4.20;

contract Auction {
    event Bid(address indexed bidder, uint endTime, uint timeLeft, uint prize);
    
    struct AuctionState {
        uint timeLeft;
        uint endTime;
        address previousWinner;
        address currentLeader;
        address owner;
    }
    
    AuctionState public state;
    
    function Auction() public {
        state.owner = msg.sender;
        state.currentLeader = msg.sender;
        state.previousWinner = msg.sender;
        state.timeLeft = 2 hours;
        state.endTime = 0;
    }
    
    function bid() payable public {
        require(msg.value == 5000000000000000);
        
        if (state.endTime == 0) {
            state.endTime = now + state.timeLeft;
        }
        
        if (state.endTime != 0 && state.endTime > now) {
            state.timeLeft -= 10 seconds;
            state.endTime = now + state.timeLeft;
            state.currentLeader = msg.sender;
            Bid(state.currentLeader, state.endTime, state.timeLeft, this.balance);
        }
        
        if (state.timeLeft == 0 || state.endTime <= now) {
            state.previousWinner = state.currentLeader;
            state.timeLeft = 2 hours;
            state.endTime = now + state.timeLeft;
            state.currentLeader = msg.sender;
            Bid(state.currentLeader, state.endTime, state.timeLeft, ((this.balance / 20) * 17) + 5000000000000000);
            state.owner.transfer((this.balance / 20) * 1);
            state.previousWinner.transfer(((this.balance - 5000000000000000) / 10) * 8);
        }
    }
    
    function() public payable {}
}