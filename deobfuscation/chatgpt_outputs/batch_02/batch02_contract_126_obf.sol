```solidity
pragma solidity ^0.4.20;

contract AuctionContract {
    using SafeMath for uint256;

    event Bid(
        uint timestamp,
        address bidder,
        uint bidAmount,
        uint leaderBid,
        uint totalDividendShares,
        uint dividendFund
    );

    event Winner(
        uint timestamp,
        address winner,
        uint payout,
        uint leaderTimestamp,
        uint totalDividendShares
    );

    event EarningsWithdrawal(
        uint timestamp,
        address withdrawer,
        uint amount
    );

    event DividendsWithdrawal(
        uint timestamp,
        address withdrawer,
        uint dividendAmount,
        uint totalDividendShares,
        uint dividendFund,
        uint totalDividendSharesAfter
    );

    uint public constant MIN_BID = 1;
    uint public constant MAX_BID = 10;
    uint public constant DIVIDEND_FUND_FRAC_TOP = 1;
    uint public constant DIVIDEND_FUND_FRAC_BOT = 10;
    uint public constant MIN_BID_FRAC_TOP = 1;
    uint public constant MIN_BID_FRAC_BOT = 5;
    uint public constant MAX_PAYOUT_FRAC_TOP = 1;
    uint public constant MAX_PAYOUT_FRAC_BOT = 10;

    mapping(address => uint) public earnings;
    uint public totalDividendShares;
    uint public dividendFund;
    uint public leaderBid;
    uint public leaderTimestamp;
    address public leader;

    struct AuctionState {
        uint bidAmount;
        uint leaderBid;
        address leader;
        uint leaderTimestamp;
        uint totalDividendShares;
        uint dividendFund;
        uint maxBid;
        address winner;
        uint payout;
        uint minBid;
        uint maxPayout;
        uint dividendFundFracTop;
        uint dividendFundFracBot;
        uint minBidFracTop;
        uint minBidFracBot;
        uint maxPayoutFracTop;
        uint maxPayoutFracBot;
    }

    AuctionState public auctionState;

    function AuctionContract() public {
        auctionState = AuctionState(
            0,
            0,
            address(0),
            0,
            0,
            0,
            0,
            address(0),
            0,
            1,
            10,
            1,
            10,
            1,
            5,
            1,
            10
        );
    }

    function placeBid() public payable {
        uint bidAmount = msg.value;
        require(bidAmount >= auctionState.minBid);

        uint maxPayout = auctionState.maxPayoutFracTop.mul(bidAmount).div(auctionState.maxPayoutFracBot);
        uint minBid = auctionState.minBidFracTop.mul(bidAmount).div(auctionState.minBidFracBot);

        if (bidAmount < minBid) {
            auctionState.totalDividendShares = auctionState.totalDividendShares.add(bidAmount);
        } else {
            earnings[msg.sender] = earnings[msg.sender].add(bidAmount);
            auctionState.totalDividendShares = auctionState.totalDividendShares.add(bidAmount);
        }

        if (bidAmount > auctionState.leaderBid) {
            auctionState.leader = msg.sender;
            auctionState.leaderBid = bidAmount;
            auctionState.leaderTimestamp = now;
            auctionState.payout = maxPayout;
            auctionState.winner = msg.sender;
            auctionState.dividendFund = auctionState.dividendFund.add(bidAmount);
        }

        Bid(now, msg.sender, bidAmount, auctionState.leaderBid, auctionState.totalDividendShares, auctionState.dividendFund);
    }

    function withdrawEarnings() public {
        require(earnings[msg.sender] > 0);
        uint amount = earnings[msg.sender];
        earnings[msg.sender] = 0;
        msg.sender.transfer(amount);
        EarningsWithdrawal(now, msg.sender, amount);
    }

    function withdrawDividends() public {
        require(earnings[msg.sender] > 0);
        uint dividendAmount = earnings[msg.sender];
        require(dividendAmount <= dividendFund);
        uint amount = dividendAmount.mul(totalDividendShares).div(dividendFund);
        require(amount <= this.balance);
        earnings[msg.sender] = earnings[msg.sender].sub(amount);
        dividendFund = dividendFund.sub(amount);
        msg.sender.transfer(amount);
        DividendsWithdrawal(now, msg.sender, dividendAmount, totalDividendShares, dividendFund, totalDividendShares);
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