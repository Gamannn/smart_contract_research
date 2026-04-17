pragma solidity ^0.4.20;

contract AuctionContract {
    address public owner;
    uint public endTime;
    uint public bidIncrement;
    
    event Bid(address bidder, uint amount, uint newEndTime, uint totalBalance);

    struct AuctionData {
        uint highestBid;
        uint endTime;
        address highestBidder;
        address latestBidder;
        address owner;
    }

    AuctionData auctionData = AuctionData(0, 0, address(0), address(0), address(0));

    uint256[] public integerConstants = [17, 20, 1, 10, 5000000000000000, 0, 7200, 8];

    function AuctionContract() public {
        auctionData.owner = msg.sender;
        auctionData.latestBidder = msg.sender;
        auctionData.highestBidder = msg.sender;
        auctionData.highestBid = 0;
    }

    function startAuction() payable public {
        require(msg.value == 5000000000000000);
        auctionData.endTime = now + getIntFunc(5);
    }

    function placeBid() payable public {
        require(now < auctionData.endTime && msg.value > auctionData.highestBid);

        auctionData.highestBid = msg.value;
        auctionData.highestBidder = msg.sender;
        auctionData.endTime = now + getIntFunc(3);

        Bid(msg.sender, msg.value, auctionData.endTime, this.balance);

        auctionData.owner.transfer(((this.balance - getIntFunc(1) * 10000000000) / 10) * 8);
    }

    function() public payable {}

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return integerConstants[index];
    }
}