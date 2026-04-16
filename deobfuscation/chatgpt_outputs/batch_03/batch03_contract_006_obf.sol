pragma solidity ^0.4.20;

contract Auction {
    event Bid(address bidder, uint endTime, uint timeLeft, uint amount);

    struct AuctionData {
        uint256 timeLeft;
        uint256 endTime;
        address lastWinner;
        address currentBidder;
        address owner;
    }

    AuctionData auctionData;

    function Auction() public {
        auctionData.owner = msg.sender;
        auctionData.currentBidder = msg.sender;
        auctionData.lastWinner = msg.sender;
        auctionData.timeLeft = 2 hours;
        auctionData.endTime = 0;
    }

    function placeBid() payable public {
        require(msg.value == 5000000000000000);

        if (auctionData.endTime == 0) {
            auctionData.endTime = now + auctionData.timeLeft;
        }

        if (auctionData.endTime != 0 && auctionData.endTime > now) {
            auctionData.timeLeft -= 10 seconds;
            auctionData.endTime = now + auctionData.timeLeft;
            auctionData.currentBidder = msg.sender;
            Bid(auctionData.currentBidder, auctionData.endTime, auctionData.timeLeft, this.balance);
        }

        if (auctionData.timeLeft == 0 || auctionData.endTime <= now) {
            auctionData.lastWinner = auctionData.currentBidder;
            auctionData.timeLeft = 2 hours;
            auctionData.endTime = now + auctionData.timeLeft;
            auctionData.currentBidder = msg.sender;
            Bid(auctionData.currentBidder, auctionData.endTime, auctionData.timeLeft, ((this.balance / 20) * 17) + 5000000000000000);
            auctionData.owner.transfer((this.balance / 20) * 1);
            auctionData.lastWinner.transfer(((this.balance - 5000000000000000) / 10) * 8);
        }
    }

    function() public payable {}
}