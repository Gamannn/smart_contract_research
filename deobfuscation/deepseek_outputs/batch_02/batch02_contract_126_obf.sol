```solidity
pragma solidity ^0.4.20;

contract Auction {
    using SafeMath for uint256;
    
    event Bid(
        uint256 timestamp,
        address indexed bidder,
        uint256 amount,
        uint256 newBid,
        uint256 round,
        uint256 pot
    );
    
    event Winner(
        uint256 timestamp,
        address indexed winner,
        uint256 payout,
        uint256 round,
        uint256 pot
    );
    
    event EarningsWithdrawal(
        uint256 timestamp,
        address indexed recipient,
        uint256 amount
    );
    
    event DividendsWithdrawal(
        uint256 timestamp,
        address indexed recipient,
        uint256 shares,
        uint256 amount,
        uint256 totalShares,
        uint256 dividendFund
    );
    
    uint256 public constant MAX_BID_FRAC_TOP = 1000;
    uint256 public constant MAX_BID_FRAC_BOT = 100;
    uint256 public constant MIN_BID_FRAC_TOP = 0;
    uint256 public constant MIN_BID_FRAC_BOT = 100;
    uint256 public constant PAYOUT_TIME = 5 minutes;
    uint256 public constant PAYOUT_FRAC_TOP = 1;
    uint256 public constant PAYOUT_FRAC_BOT = 10;
    uint256 public constant DIVIDEND_FUND_FRAC_TOP = 1;
    uint256 public constant DIVIDEND_FUND_FRAC_BOT = 100;
    
    mapping(address => uint256) public earnings;
    mapping(address => uint256) public dividendShares;
    
    uint256 public totalDividendShares;
    uint256 public dividendFund;
    uint256 public round;
    address public leader;
    uint256 public leaderBid;
    uint256 public leaderTimestamp;
    uint256 public pot;
    
    function Auction() public payable {
        require(msg.value > 0);
        round = 0;
        pot = msg.value;
        leader = msg.sender;
        leaderTimestamp = now;
        leaderBid = 0;
        Bid(now, msg.sender, msg.value, msg.value, round, pot);
    }
    
    function bid() public payable {
        require(msg.value > 0);
        
        uint256 maxBid = pot.mul(MAX_BID_FRAC_TOP).div(MAX_BID_FRAC_BOT);
        uint256 timeElapsed = now.sub(leaderTimestamp);
        uint256 payoutTime = PAYOUT_TIME;
        
        if (timeElapsed > payoutTime) {
            uint256 payout = pot.mul(PAYOUT_FRAC_TOP).div(PAYOUT_FRAC_BOT);
            if (payout > maxBid) {
                payout = maxBid;
            }
            
            pot = pot.sub(payout);
            earnings[leader] = earnings[leader].add(payout);
            Winner(now, leader, payout, round, pot);
            
            uint256 dividendShare = pot.mul(DIVIDEND_FUND_FRAC_TOP).div(DIVIDEND_FUND_FRAC_BOT);
            dividendFund = dividendFund.add(dividendShare);
            pot = pot.sub(dividendShare);
            
            round = round.add(1);
            leader = msg.sender;
            leaderBid = msg.value;
            leaderTimestamp = now;
            pot = pot.add(msg.value);
            
            if (msg.value > maxBid) {
                leaderBid = maxBid;
            }
            
            Bid(now, msg.sender, msg.value, leaderBid, round, pot);
            return;
        }
        
        uint256 minBid = leaderBid.mul(MIN_BID_FRAC_TOP).div(MIN_BID_FRAC_BOT).add(1);
        uint256 bidAmountToDividend = msg.value.mul(DIVIDEND_FUND_FRAC_TOP).div(DIVIDEND_FUND_FRAC_BOT);
        uint256 bidAmountToPot = msg.value.sub(bidAmountToDividend);
        
        if (msg.value < minBid) {
            dividendFund = dividendFund.add(msg.value);
        } else {
            dividendFund = dividendFund.add(bidAmountToDividend);
            pot = pot.add(bidAmountToPot);
        }
        
        uint256 newShares = bidAmountToDividend.mul(totalDividendShares).div(dividendFund);
        dividendShares[msg.sender] = dividendShares[msg.sender].add(newShares);
        totalDividendShares = totalDividendShares.add(newShares);
        
        round = round.add(1);
        leader = msg.sender;
        leaderBid = msg.value;
        leaderTimestamp = now;
        
        if (msg.value > maxBid) {
            leaderBid = maxBid;
        }
        
        Bid(now, msg.sender, msg.value, leaderBid, round, pot);
    }
    
    function withdrawEarnings() public {
        require(earnings[msg.sender] > 0);
        uint256 amount = earnings[msg.sender];
        earnings[msg.sender] = 0;
        msg.sender.transfer(amount);
        EarningsWithdrawal(now, msg.sender, amount);
    }
    
    function withdrawDividends() public {
        require(dividendShares[msg.sender] > 0);
        uint256 shares = dividendShares[msg.sender];
        require(shares <= totalDividendShares);
        
        uint256 amount = dividendFund.mul(shares).div(totalDividendShares);
        require(amount <= this.balance);
        
        dividendShares[msg.sender] = 0;
        totalDividendShares = totalDividendShares.sub(shares);
        dividendFund = dividendFund.sub(amount);
        msg.sender.transfer(amount);
        
        DividendsWithdrawal(now, msg.sender, shares, amount, totalDividendShares, dividendFund);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
```