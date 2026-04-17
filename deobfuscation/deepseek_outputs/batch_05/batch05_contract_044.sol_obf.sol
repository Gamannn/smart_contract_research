pragma solidity ^0.4.11;

contract SimpleAuction {
    address public beneficiary;
    uint public auctionEndTime;
    uint public auctionStartTime;
    uint public highestBid;
    address public highestBidder;
    mapping(address => uint) public pendingReturns;
    bool public ended;
    
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    function SimpleAuction() {
        beneficiary = 0x7Ef6fA8683491521223Af5A69b923E771fF2e73A;
        auctionStartTime = now;
        auctionEndTime = auctionStartTime + 7 days;
    }

    function bid() payable {
        require(now <= auctionEndTime);
        require(msg.value > highestBid);
        
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        HighestBidIncreased(msg.sender, highestBid);
    }

    function withdraw() returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() {
        require(now >= auctionEndTime);
        ended = true;
        AuctionEnded(highestBidder, highestBid);
    }
}