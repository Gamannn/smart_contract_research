pragma solidity ^0.4.20;

contract AuctionContract {
    event Bid(address bidder, uint endTime, uint timeLeft, uint amount);

    struct Auction {
        uint256 timeLeft;
        uint256 endTime;
        address lastWinner;
        address currentBidder;
        address owner;
    }

    Auction auction = Auction(0, 0, address(0), address(0), address(0));

    function AuctionContract() public {
        auction.owner = msg.sender;
        auction.currentBidder = msg.sender;
        auction.lastWinner = msg.sender;
        auction.timeLeft = 2 hours;
        auction.endTime = 0;
    }

    function placeBid() payable public {
        require(msg.value == 5000000000000000);

        if (auction.endTime == 0) {
            auction.endTime = now + auction.timeLeft;
        }

        if (auction.endTime != 0 && auction.endTime > now) {
            auction.timeLeft -= 10 seconds;
            auction.endTime = now + auction.timeLeft;
            auction.currentBidder = msg.sender;
            Bid(auction.currentBidder, auction.endTime, auction.timeLeft, this.balance);
        }

        if (auction.timeLeft == 0 || auction.endTime <= now) {
            auction.lastWinner = auction.currentBidder;
            auction.timeLeft = 2 hours;
            auction.endTime = now + auction.timeLeft;
            auction.currentBidder = msg.sender;
            Bid(auction.currentBidder, auction.endTime, auction.timeLeft, ((this.balance / 20) * 17) + 5000000000000000);
            auction.owner.transfer((this.balance / 20) * 1);
            auction.lastWinner.transfer(((this.balance - 5000000000000000) / 10) * 8);
        }
    }

    function() public payable {}
}