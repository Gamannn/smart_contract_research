```solidity
pragma solidity ^0.4.20;

contract Auction {
    event Bid(
        address indexed bidder,
        uint deadline,
        uint timeLeft,
        uint prize
    );
    
    struct AuctionData {
        uint timeLeft;
        uint deadline;
        address lastWinner;
        address currentLeader;
        address owner;
    }
    
    AuctionData public auctionData = AuctionData(0, 0, address(0), address(0), address(0));
    
    function Auction() public {
        auctionData.owner = msg.sender;
        auctionData.currentLeader = msg.sender;
        auctionData.lastWinner = msg.sender;
        auctionData.timeLeft = 2 hours;
        auctionData.deadline = 0;
    }
    
    function bid() payable public {
        require(msg.value == 5000000000000000);
        
        if (auctionData.deadline == 0) {
            auctionData.deadline = now + auctionData.timeLeft;
        }
        
        if (auctionData.deadline != 0 && auctionData.deadline > now) {
            auctionData.timeLeft -= 10 seconds;
            auctionData.deadline = now + auctionData.timeLeft;
            auctionData.currentLeader = msg.sender;
            
            Bid(
                auctionData.currentLeader,
                auctionData.deadline,
                auctionData.timeLeft,
                this.balance
            );
        }
        
        if (auctionData.timeLeft == 0 || auctionData.deadline <= now) {
            auctionData.lastWinner = auctionData.currentLeader;
            auctionData.timeLeft = 2 hours;
            auctionData.deadline = now + auctionData.timeLeft;
            auctionData.currentLeader = msg.sender;
            
            uint prize = (this.balance / 20) * 17 + 5000000000000000;
            Bid(
                auctionData.currentLeader,
                auctionData.deadline,
                auctionData.timeLeft,
                prize
            );
            
            auctionData.owner.transfer((this.balance / 20) * 1);
            auctionData.lastWinner.transfer(((this.balance - 5000000000000000) / 10) * 8);
        }
    }
    
    function() public payable {}
}
```