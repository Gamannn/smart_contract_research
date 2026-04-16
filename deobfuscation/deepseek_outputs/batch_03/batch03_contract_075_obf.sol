```solidity
pragma solidity ^0.4.20;

contract Auction {
    event Bid(
        address indexed currentLeader,
        uint deadline,
        uint timeRemaining,
        uint prize
    );
    
    struct AuctionData {
        uint timeRemaining;
        uint deadline;
        address previousWinner;
        address currentLeader;
        address owner;
    }
    
    AuctionData public auctionData = AuctionData(0, 0, address(0), address(0), address(0));
    
    function Auction() public {
        auctionData.owner = msg.sender;
        auctionData.currentLeader = msg.sender;
        auctionData.previousWinner = msg.sender;
        auctionData.timeRemaining = 2 hours;
        auctionData.deadline = 0;
    }
    
    function placeBid() payable public {
        require(msg.value == 5000000000000000);
        
        if (auctionData.deadline == 0) {
            auctionData.deadline = now + auctionData.timeRemaining;
        }
        
        if (auctionData.deadline != 0 && auctionData.deadline > now) {
            auctionData.timeRemaining -= 10 seconds;
            auctionData.deadline = now + auctionData.timeRemaining;
            auctionData.currentLeader = msg.sender;
            
            Bid(
                auctionData.currentLeader,
                auctionData.deadline,
                auctionData.timeRemaining,
                this.balance
            );
        }
        
        if (auctionData.timeRemaining == 0 || auctionData.deadline <= now) {
            auctionData.previousWinner = auctionData.currentLeader;
            auctionData.timeRemaining = 2 hours;
            auctionData.deadline = now + auctionData.timeRemaining;
            auctionData.currentLeader = msg.sender;
            
            uint prize = (this.balance / 20) * 17 + 5000000000000000;
            Bid(
                auctionData.currentLeader,
                auctionData.deadline,
                auctionData.timeRemaining,
                prize
            );
            
            auctionData.owner.transfer(this.balance / 20);
            auctionData.previousWinner.transfer(((this.balance - 5000000000000000) / 10) * 8);
        }
    }
    
    function() public payable {}
}
```