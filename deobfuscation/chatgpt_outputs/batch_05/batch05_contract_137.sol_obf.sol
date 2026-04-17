```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint256;

    mapping(address => uint256) public investments;
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public pendingWithdrawals;
    mapping(address => uint256) public referralRewards;

    uint256 public constant MINIMUM_INVESTMENT = 2 ether;
    uint256 public constant REFERRAL_PERCENTAGE = 10;
    uint256 public constant DAILY_INTEREST = 5;
    uint256 public constant INTEREST_DIVISOR = 100;
    uint256 public constant SECONDS_IN_A_DAY = 1440;

    address public owner;
    address public ownerWallet;

    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed referrer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        ownerWallet = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner, address newOwnerWallet) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        ownerWallet = newOwnerWallet;
    }

    function() public payable {
        invest(0x0);
    }

    function invest(address referrer) public payable {
        require(msg.value >= MINIMUM_INVESTMENT);

        address investor = msg.sender;

        if (referrer != address(0) && investments[referrer] >= MINIMUM_INVESTMENT) {
            referralRewards[referrer] = referralRewards[referrer].add(msg.value.mul(REFERRAL_PERCENTAGE).div(INTEREST_DIVISOR));
        }

        if (investments[investor] > 0) {
            withdraw();
        }

        investments[investor] = investments[investor].add(msg.value);
        lastInvestmentTime[investor] = block.timestamp;

        ownerWallet.transfer(msg.value.mul(DAILY_INTEREST).div(INTEREST_DIVISOR));

        emit Invest(investor, msg.value);
    }

    function calculateInterest(address investor) view public returns (uint256) {
        uint256 timeDifference = now.sub(lastInvestmentTime[investor]).div(1 minutes);
        uint256 dailyInterest = investments[investor].mul(DAILY_INTEREST).div(INTEREST_DIVISOR);
        uint256 interest = dailyInterest.mul(timeDifference).div(SECONDS_IN_A_DAY);
        return interest;
    }

    function withdraw() public returns (bool) {
        require(lastInvestmentTime[msg.sender] > 0);

        uint256 interest = calculateInterest(msg.sender);

        if (address(this).balance > interest) {
            if (interest > 0) {
                pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].add(interest);
                msg.sender.transfer(interest);
                emit Withdraw(msg.sender, interest);
            }
            return true;
        } else {
            return false;
        }
    }

    function claimReferralReward() public {
        uint256 reward = referralRewards[msg.sender];
        if (reward >= MINIMUM_INVESTMENT) {
            if (address(this).balance > reward) {
                referralRewards[msg.sender] = 0;
                msg.sender.transfer(reward);
                emit Bounty(msg.sender, reward);
            }
        }
    }

    function getPendingInterest() public view returns (uint256) {
        return calculateInterest(msg.sender);
    }

    function getPendingWithdrawals(address investor) public view returns (uint256) {
        return pendingWithdrawals[investor];
    }

    function getInvestments(address investor) public view returns (uint256) {
        return investments[investor];
    }

    function getReferralRewards(address referrer) public view returns (uint256) {
        return referralRewards[referrer];
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