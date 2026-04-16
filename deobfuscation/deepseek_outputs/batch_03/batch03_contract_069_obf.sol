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
        address lastBidder;
        address owner;
    }
    
    AuctionData public auctionData;
    
    constructor() public {
        auctionData.owner = msg.sender;
        auctionData.lastBidder = msg.sender;
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
            auctionData.lastBidder = msg.sender;
            Bid(auctionData.lastBidder, auctionData.deadline, auctionData.timeLeft, address(this).balance);
        }
        
        if (auctionData.timeLeft == 0 || auctionData.deadline <= now) {
            auctionData.lastWinner = auctionData.lastBidder;
            auctionData.timeLeft = 2 hours;
            auctionData.deadline = now + auctionData.timeLeft;
            auctionData.lastBidder = msg.sender;
            
            uint prize = (address(this).balance / 20) * 17 + 5000000000000000;
            Bid(auctionData.lastBidder, auctionData.deadline, auctionData.timeLeft, prize);
            
            auctionData.owner.transfer(address(this).balance / 20);
            auctionData.lastWinner.transfer(((address(this).balance - 5000000000000000) / 10) * 8);
        }
    }
    
    function() public payable {}
}
```