```solidity
pragma solidity ^0.4.20;

contract Auction {
    address public owner;
    address public latestBidder;
    address public latestWinner;
    uint public endTime;
    uint public latestBid;
    
    event Bid(address indexed bidder, uint amount, uint newEndTime, uint refundAmount);
    
    function Auction() public {
        owner = msg.sender;
        latestBidder = msg.sender;
        latestWinner = msg.sender;
        endTime = now + 7200;
        latestBid = 0;
    }
    
    function placeBid() payable public {
        require(msg.value == 5000000000000000);
        
        if (endTime > now) {
            endTime = endTime + 300;
            latestBid = latestBid + (10 * msg.value);
            latestBidder = msg.sender;
            
            Bid(latestBidder, msg.value, endTime, this.balance);
        }
        
        latestWinner = latestBidder;
        endTime = now + 7200;
        latestBid = latestBid + msg.value;
        
        Bid(latestBidder, msg.value, endTime, ((this.balance / 20) * 17) + 5000000000000000);
        
        owner.transfer(((this.balance - 100000000000000) / 10) * 8);
    }
    
    struct AuctionState {
        uint latestBid;
        uint endTime;
        address latestWinner;
        address latestBidder;
        address owner;
    }
    
    AuctionState auctionState = AuctionState(0, 0, address(0), address(0), address(0));
    
    function() public payable {}
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    uint256[] public _integer_constant = [17, 20, 1, 10, 5000000000000000, 0, 7200, 8];
}
```