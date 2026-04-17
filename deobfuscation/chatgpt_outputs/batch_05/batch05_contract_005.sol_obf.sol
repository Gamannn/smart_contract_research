```solidity
pragma solidity ^0.4.19;

contract AuctionContract {
    using SafeMath for uint256;

    event NewRound(uint roundId, uint pot, uint deadline);
    event Bid(uint roundId, address bidder, uint amount, uint newPot);
    event NewLeader(uint roundId, address leader, uint newPot, uint newDeadline);
    event Winner(uint roundId, address winner, uint winnings, uint nextPot);
    event EarningsWithdrawal(uint roundId, address withdrawer, uint amount);
    event DividendsWithdrawal(uint roundId, address withdrawer, uint dividendShares, uint amount, uint totalDividendShares, uint totalDividendFund);

    uint public constant ROUND_DURATION = 90 minutes;
    uint public constant BASE_DURATION = 30 minutes;
    uint public constant MINIMUM_DURATION = 5 minutes;
    uint public constant DURATION_DECREASE_PER_ETHER = 1 minutes;
    uint public constant LEADER_FRAC_TOP = 20;
    uint public constant LEADER_FRAC_BOT = 100;
    uint public constant DEV_FEE_FRAC_TOP = 5;
    uint public constant DEV_FEE_FRAC_BOT = 100;
    uint public constant DIVIDEND_FUND_FRAC_TOP = 20;
    uint public constant DIVIDEND_FUND_FRAC_BOT = 100;
    uint public constant NEXT_POT_FRAC_TOP = 20;
    uint public constant NEXT_POT_FRAC_BOT = 100;

    mapping(address => uint) public earnings;
    mapping(address => uint) public dividendShares;
    uint public totalDividendShares;
    uint public totalDividendFund;

    struct Round {
        uint deadline;
        address leader;
        uint pot;
        uint roundId;
        uint totalDividendShares;
        uint totalDividendFund;
        address owner;
        uint dividendFund;
        uint devFee;
        uint leaderAmount;
        uint minLeaderAmount;
        uint nextPot;
        uint leaderEarnings;
        uint devFeeAmount;
        uint dividendFundAmount;
        uint minLeaderFracBot;
        uint leaderFracTop;
        uint leaderFracBot;
        uint devFeeFracTop;
        uint devFeeFracBot;
        uint dividendFundFracTop;
        uint dividendFundFracBot;
        uint nextPotFracTop;
        uint nextPotFracBot;
    }

    Round public currentRound;

    function AuctionContract() public payable {
        currentRound.roundId = 1;
        currentRound.pot = msg.value;
        currentRound.leader = msg.sender;
        currentRound.deadline = computeDeadline();
        NewRound(now, currentRound.pot, currentRound.deadline);
        NewLeader(currentRound.roundId, currentRound.leader, currentRound.pot, currentRound.deadline);
    }

    function computeDeadline() internal view returns (uint) {
        uint durationDecrease = currentRound.pot.div(1 ether).mul(DURATION_DECREASE_PER_ETHER);
        uint duration = BASE_DURATION.sub(durationDecrease);
        if (duration < MINIMUM_DURATION) {
            duration = MINIMUM_DURATION;
        }
        return now.add(duration);
    }

    modifier advanceRoundIfNeeded() {
        if (now > currentRound.deadline) {
            uint leaderEarnings = currentRound.pot.mul(LEADER_FRAC_TOP).div(LEADER_FRAC_BOT);
            uint nextPot = currentRound.pot.mul(NEXT_POT_FRAC_TOP).div(NEXT_POT_FRAC_BOT);
            earnings[currentRound.leader] = earnings[currentRound.leader].add(leaderEarnings);
            currentRound.roundId++;
            currentRound.pot = nextPot;
            currentRound.leader = msg.sender;
            currentRound.deadline = computeDeadline();
            NewRound(currentRound.roundId, currentRound.pot, currentRound.deadline);
            NewLeader(currentRound.roundId, currentRound.leader, currentRound.pot, currentRound.deadline);
        }
        _;
    }

    function placeBid() public payable advanceRoundIfNeeded {
        uint minLeaderAmount = currentRound.pot.mul(LEADER_FRAC_TOP).div(LEADER_FRAC_BOT);
        uint devFeeAmount = msg.value.mul(DEV_FEE_FRAC_TOP).div(DEV_FEE_FRAC_BOT);
        uint dividendFundAmount = msg.value.mul(DIVIDEND_FUND_FRAC_TOP).div(DIVIDEND_FUND_FRAC_BOT);
        uint bidAmountToPot = msg.value.sub(devFeeAmount).sub(dividendFundAmount);

        earnings[currentRound.owner] = earnings[currentRound.owner].add(devFeeAmount);
        currentRound.pot = currentRound.pot.add(bidAmountToPot);
        Bid(now, msg.sender, msg.value, currentRound.pot);

        if (msg.value >= minLeaderAmount) {
            uint dividendShares = msg.value.mul(DIVIDEND_FUND_FRAC_TOP).div(DIVIDEND_FUND_FRAC_BOT);
            dividendShares[msg.sender] = dividendShares[msg.sender].add(dividendShares);
            totalDividendShares = totalDividendShares.add(dividendShares);
            totalDividendFund = totalDividendFund.add(dividendFundAmount);
            currentRound.leader = msg.sender;
            currentRound.deadline = computeDeadline();
        }
    }

    function withdrawEarnings() public advanceRoundIfNeeded {
        require(earnings[msg.sender] > 0);
        uint amount = earnings[msg.sender];
        earnings[msg.sender] = 0;
        msg.sender.transfer(amount);
        EarningsWithdrawal(now, msg.sender, amount);
    }

    function withdrawDividends() public {
        require(dividendShares[msg.sender] > 0);
        uint dividendSharesAmount = dividendShares[msg.sender];
        uint amount = totalDividendFund.mul(dividendSharesAmount).div(totalDividendShares);
        dividendShares[msg.sender] = 0;
        totalDividendShares = totalDividendShares.sub(dividendSharesAmount);
        totalDividendFund = totalDividendFund.sub(amount);
        msg.sender.transfer(amount);
        DividendsWithdrawal(now, msg.sender, dividendSharesAmount, amount, totalDividendShares, totalDividendFund);
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