```solidity
pragma solidity ^0.4.20;

contract Auction {
    event Bid(
        address indexed highestBidder,
        uint auctionEndTime,
        uint timeRemaining,
        uint prizeAmount
    );
    
    struct AuctionData {
        uint timeRemaining;
        uint auctionEndTime;
        address previousWinner;
        address highestBidder;
        address owner;
    }
    
    AuctionData public auctionData;
    
    function Auction() public {
        auctionData.owner = msg.sender;
        auctionData.highestBidder = msg.sender;
        auctionData.previousWinner = msg.sender;
        auctionData.timeRemaining = 2 hours;
        auctionData.auctionEndTime = 0;
    }
    
    function placeBid() payable public {
        require(msg.value == 5000000000000000);
        
        if (auctionData.auctionEndTime == 0) {
            auctionData.auctionEndTime = now + auctionData.timeRemaining;
        }
        
        if (auctionData.auctionEndTime != 0 && auctionData.auctionEndTime > now) {
            auctionData.timeRemaining -= 10 seconds;
            auctionData.auctionEndTime = now + auctionData.timeRemaining;
            auctionData.highestBidder = msg.sender;
            
            Bid(
                auctionData.highestBidder,
                auctionData.auctionEndTime,
                auctionData.timeRemaining,
                this.balance
            );
        }
        
        if (auctionData.timeRemaining == 0 || auctionData.auctionEndTime <= now) {
            auctionData.previousWinner = auctionData.highestBidder;
            auctionData.timeRemaining = 2 hours;
            auctionData.auctionEndTime = now + auctionData.timeRemaining;
            auctionData.highestBidder = msg.sender;
            
            uint prizeAmount = ((this.balance / 20) * 17) + 5000000000000000;
            
            Bid(
                auctionData.highestBidder,
                auctionData.auctionEndTime,
                auctionData.timeRemaining,
                prizeAmount
            );
            
            auctionData.owner.transfer((this.balance / 20) * 1);
            auctionData.previousWinner.transfer(((this.balance - 5000000000000000) / 10) * 8);
        }
    }
    
    function() public payable {}
}
```