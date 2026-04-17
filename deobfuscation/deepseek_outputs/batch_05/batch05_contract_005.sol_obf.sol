```solidity
pragma solidity ^0.4.19;

contract Fomo3D {
    using SafeMath for uint256;
    
    event NewRound(
        uint256 indexed roundId,
        uint256 pot,
        uint256 deadline
    );
    
    event Bid(
        uint256 indexed roundId,
        address indexed bidder,
        uint256 amount,
        uint256 pot
    );
    
    event NewLeader(
        uint256 indexed roundId,
        address indexed leader,
        uint256 pot,
        uint256 deadline
    );
    
    event Winner(
        uint256 indexed roundId,
        address indexed winner,
        uint256 earnings,
        uint256 pot
    );
    
    event EarningsWithdrawal(
        uint256 indexed roundId,
        address indexed winner,
        uint256 amount
    );
    
    event DividendsWithdrawal(
        uint256 indexed roundId,
        address indexed shareholder,
        uint256 shares,
        uint256 amount,
        uint256 totalShares,
        uint256 dividendFund
    );
    
    uint256 public constant BASE_DURATION = 90 minutes;
    uint256 public constant MINIMUM_DURATION = 30 minutes;
    uint256 public constant DURATION_DECREASE_PER_ETHER = 30 minutes;
    
    uint256 public constant DEV_FEE_FRAC_TOP = 5;
    uint256 public constant DEV_FEE_FRAC_BOT = 100;
    
    uint256 public constant DIVIDEND_FUND_FRAC_TOP = 20;
    uint256 public constant DIVIDEND_FUND_FRAC_BOT = 100;
    
    uint256 public constant NEXT_POT_FRAC_TOP = 120;
    uint256 public constant NEXT_POT_FRAC_BOT = 100;
    
    uint256 public constant MIN_LEADER_FRAC_TOP = 1;
    uint256 public constant MIN_LEADER_FRAC_BOT = 100;
    
    uint256 public roundId;
    uint256 public pot;
    uint256 public deadline;
    address public leader;
    address public owner;
    
    uint256 public dividendFund;
    uint256 public totalDividendShares;
    mapping(address => uint256) public dividendShares;
    mapping(address => uint256) public earnings;
    
    function Fomo3D() public payable {
        require(msg.value > 0);
        owner = msg.sender;
        roundId = 1;
        pot = msg.value;
        leader = owner;
        deadline = computeDeadline();
        NewRound(roundId, pot, deadline);
        NewLeader(roundId, leader, pot, deadline);
    }
    
    function computeDeadline() internal view returns (uint256) {
        uint256 durationDecrease = DURATION_DECREASE_PER_ETHER.mul(pot.div(1 ether));
        uint256 duration;
        if (durationDecrease > BASE_DURATION) {
            duration = MINIMUM_DURATION;
        } else {
            duration = BASE_DURATION.sub(durationDecrease);
        }
        if (duration < MINIMUM_DURATION) {
            duration = MINIMUM_DURATION;
        }
        return now.add(duration);
    }
    
    modifier advanceRoundIfNeeded() {
        if (now > deadline) {
            uint256 nextPot = pot.mul(NEXT_POT_FRAC_TOP).div(NEXT_POT_FRAC_BOT);
            uint256 leaderEarnings = pot.sub(nextPot);
            
            earnings[leader] = earnings[leader].add(leaderEarnings);
            Winner(roundId, leader, leaderEarnings, pot);
            
            roundId++;
            pot = nextPot;
            deadline = computeDeadline();
            leader = owner;
            NewRound(roundId, pot, deadline);
            NewLeader(roundId, leader, pot, deadline);
        }
        _;
    }
    
    function bid() public payable advanceRoundIfNeeded {
        require(msg.value > 0);
        
        uint256 minLeaderAmount = pot.mul(MIN_LEADER_FRAC_TOP).div(MIN_LEADER_FRAC_BOT);
        uint256 devFee = msg.value.mul(DEV_FEE_FRAC_TOP).div(DEV_FEE_FRAC_BOT);
        uint256 dividendFundAmount = msg.value.mul(DIVIDEND_FUND_FRAC_TOP).div(DIVIDEND_FUND_FRAC_BOT);
        uint256 amountToPot = msg.value.sub(devFee).sub(dividendFundAmount);
        
        earnings[owner] = earnings[owner].add(devFee);
        dividendFund = dividendFund.add(dividendFundAmount);
        pot = pot.add(amountToPot);
        
        Bid(roundId, msg.sender, msg.value, pot);
        
        if (msg.value >= minLeaderAmount) {
            uint256 dividendSharesAmount = msg.value.mul(100);
            dividendShares[msg.sender] = dividendShares[msg.sender].add(dividendSharesAmount);
            totalDividendShares = totalDividendShares.add(dividendSharesAmount);
            leader = msg.sender;
            deadline = computeDeadline();
            NewLeader(roundId, leader, pot, deadline);
        }
    }
    
    function withdrawEarnings() public advanceRoundIfNeeded {
        require(earnings[msg.sender] > 0);
        require(earnings[msg.sender] <= this.balance);
        
        uint256 amount = earnings[msg.sender];
        earnings[msg.sender] = 0;
        msg.sender.transfer(amount);
        EarningsWithdrawal(roundId, msg.sender, amount);
    }
    
    function withdrawDividends() public {
        require(dividendShares[msg.sender] > 0);
        
        uint256 shares = dividendShares[msg.sender];
        assert(shares <= totalDividendShares);
        
        uint256 amount = dividendFund.mul(shares).div(totalDividendShares);
        assert(amount <= this.balance);
        
        dividendShares[msg.sender] = 0;
        totalDividendShares = totalDividendShares.sub(shares);
        dividendFund = dividendFund.sub(amount);
        msg.sender.transfer(amount);
        
        DividendsWithdrawal(roundId, msg.sender, shares, amount, totalDividendShares, dividendFund);
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