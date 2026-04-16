pragma solidity ^0.4.20;

contract Auction {
    event Bid(address indexed bidder, uint endTime, uint timeLeft, uint prize);
    
    struct AuctionData {
        uint timeLeft;
        uint endTime;
        address lastWinner;
        address lastBidder;
        address owner;
    }
    
    AuctionData public data;
    
    function Auction() public {
        data.owner = msg.sender;
        data.lastBidder = msg.sender;
        data.lastWinner = msg.sender;
        data.timeLeft = 2 hours;
        data.endTime = 0;
    }
    
    function bid() payable public {
        require(msg.value == 5000000000000000);
        
        if (data.endTime == 0) {
            data.endTime = now + data.timeLeft;
        }
        
        if (data.endTime != 0 && data.endTime > now) {
            data.timeLeft -= 10 seconds;
            data.endTime = now + data.timeLeft;
            data.lastBidder = msg.sender;
            Bid(data.lastBidder, data.endTime, data.timeLeft, this.balance);
        }
        
        if (data.timeLeft == 0 || data.endTime <= now) {
            data.lastWinner = data.lastBidder;
            data.timeLeft = 2 hours;
            data.endTime = now + data.timeLeft;
            data.lastBidder = msg.sender;
            
            uint prize = (this.balance / 20) * 17 + 5000000000000000;
            Bid(data.lastBidder, data.endTime, data.timeLeft, prize);
            
            data.owner.transfer(this.balance / 20);
            data.lastWinner.transfer(((this.balance - 5000000000000000) / 10) * 8);
        }
    }
    
    function() public payable {}
}