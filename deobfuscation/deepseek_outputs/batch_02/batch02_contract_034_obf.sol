```solidity
pragma solidity ^0.4.20;

contract EtherHell {
    using SafeMath for uint256;
    
    event Bid(
        uint timestamp,
        address bidder,
        uint amount,
        uint effectiveBid,
        uint round,
        uint pot
    );
    
    event Winner(
        uint timestamp,
        address winner,
        uint payout,
        uint potAfterPayout,
        uint round
    );
    
    event EarningsWithdrawal(
        uint timestamp,
        address recipient,
        uint amount
    );
    
    event DividendsWithdrawal(
        uint timestamp,
        address recipient,
        uint shares,
        uint amount,
        uint totalShares,
        uint dividendFund
    );
    
    uint public constant PAYOUT_FRAC_TOP = 9;
    uint public constant PAYOUT_FRAC_BOT = 10;
    uint public constant MAX_BID_FRAC_TOP = 1;
    uint public constant MAX_BID_FRAC_BOT = 100;
    uint public constant DIVIDEND_FUND_FRAC_TOP = 1;
    uint public constant DIVIDEND_FUND_FRAC_BOT = 10;
    uint public constant PAYOUT_TIME = 300 seconds;
    
    mapping(address => uint) public earnings;
    mapping(address => uint) public dividendShares;
    
    uint public round;
    uint public pot;
    uint public dividendFund;
    uint public totalDividendShares;
    
    address public leader;
    uint public leaderBid;
    uint public leaderTimestamp;
    
    function EtherHell() public payable {
        require(msg.value > 0);
        round = 1;
        pot = msg.value;
        dividendFund = 0;
        totalDividendShares = 0;
        leader = msg.sender;
        leaderBid = msg.value;
        leaderTimestamp = now;
        Bid(now, msg.sender, 0, 0, round, pot);
    }
    
    function bid() public payable {
        uint maxBid = pot.mul(MAX_BID_FRAC_TOP).div(MAX_BID_FRAC_BOT);
        uint timeElapsed = now.sub(leaderTimestamp);
        uint payoutInterval = PAYOUT_TIME.mul(PAYOUT_FRAC_TOP).div(PAYOUT_FRAC_BOT);
        
        if (timeElapsed > payoutInterval) {
            uint totalPayout = pot.mul(PAYOUT_FRAC_TOP).div(PAYOUT_FRAC_BOT);
            if (totalPayout > maxBid) {
                totalPayout = maxBid;
            }
            
            earnings[leader] = earnings[leader].add(totalPayout);
            pot = pot.sub(totalPayout);
            
            uint bidAmountToDividendFund = pot.mul(DIVIDEND_FUND_FRAC_TOP).div(DIVIDEND_FUND_FRAC_BOT);
            pot = pot.sub(bidAmountToDividendFund);
            dividendFund = dividendFund.add(bidAmountToDividendFund);
            
            Winner(now, leader, totalPayout, pot, round);
            
            round++;
            leader = msg.sender;
            leaderTimestamp = now;
            leaderBid = msg.value;
            
            if (leaderBid > maxBid) {
                leaderBid = maxBid;
            }
            
            Bid(now, msg.sender, msg.value, leaderBid, round, pot);
            return;
        }
        
        uint dividendSharePrice;
        if (totalDividendShares == 0) {
            dividendSharePrice = dividendFund.mul(DIVIDEND_FUND_FRAC_TOP).div(DIVIDEND_FUND_FRAC_BOT);
        } else {
            dividendSharePrice = dividendFund.div(totalDividendShares);
        }
        
        pot = pot.add(dividendFund);
        dividendFund = 0;
        
        if (msg.value > maxBid) {
            uint excess = msg.value.sub(maxBid).mul(DIVIDEND_FUND_FRAC_TOP).div(DIVIDEND_FUND_FRAC_BOT);
            uint shares = excess.div(dividendSharePrice);
            dividendShares[msg.sender] = dividendShares[msg.sender].add(shares);
            totalDividendShares = totalDividendShares.add(shares);
        }
        
        round++;
        leader = msg.sender;
        leaderTimestamp = now;
        leaderBid = msg.value;
        
        if (leaderBid > maxBid) {
            leaderBid = maxBid;
        }
        
        pot = pot.add(leaderBid);
        Bid(now, msg.sender, msg.value, leaderBid, round, pot);
    }
    
    function withdrawEarnings() public {
        require(earnings[msg.sender] > 0);
        assert(earnings[msg.sender] <= this.balance);
        uint amount = earnings[msg.sender];
        earnings[msg.sender] = 0;
        msg.sender.transfer(amount);
        EarningsWithdrawal(now, msg.sender, amount);
    }
    
    function withdrawDividends() public {
        require(dividendShares[msg.sender] > 0);
        uint shares = dividendShares[msg.sender];
        uint amount = dividendFund.mul(shares).div(totalDividendShares);
        assert(amount <= this.balance);
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