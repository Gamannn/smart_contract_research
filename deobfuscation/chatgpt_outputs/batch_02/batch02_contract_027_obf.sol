```solidity
pragma solidity ^0.4.25;

contract InvestmentContract {
    using SafeMath for uint256;

    mapping(address => uint256) public investments;
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public withdrawnAmount;
    mapping(address => uint256) public referralRewards;
    mapping(address => uint256) public totalWithdrawn;

    uint256 public constant MINIMUM_INVESTMENT = 2 ether;
    uint256 public constant REFERRAL_PERCENTAGE = 5;
    uint256 public constant DAILY_INTEREST = 10 finney;
    uint256 public constant MAX_DAILY_WITHDRAWAL = 100 ether;

    address public owner;
    address public feeReceiver;

    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event WithdrawShare(address indexed investor, uint256 amount);
    event Bounty(address indexed hunter, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _feeReceiver) public {
        owner = msg.sender;
        feeReceiver = _feeReceiver;
    }

    function transferOwnership(address newOwner, address newFeeReceiver) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        feeReceiver = newFeeReceiver;
    }

    function() public payable {
        invest(0x0);
    }

    function invest(address referrer) public payable {
        require(msg.value >= MINIMUM_INVESTMENT);
        address investor = msg.sender;

        if (referrer != address(0) && referrer != investor) {
            referralRewards[referrer] = referralRewards[referrer].add(msg.value.mul(REFERRAL_PERCENTAGE).div(100));
        }

        if (investments[investor] > 0) {
            if (canWithdraw(investor)) {
                withdrawnAmount[investor] = 0;
            }
        }

        investments[investor] = investments[investor].add(msg.value);
        lastInvestmentTime[investor] = now;
        feeReceiver.transfer(msg.value.mul(REFERRAL_PERCENTAGE).div(100));
        emit Invest(investor, msg.value);
    }

    function calculateInterest(address investor) public view returns (uint256) {
        uint256 timeElapsed = now.sub(lastInvestmentTime[investor]).div(1 minutes);
        uint256 dailyInterest = investments[investor].mul(DAILY_INTEREST).div(100);
        uint256 interest = dailyInterest.mul(timeElapsed).div(720);
        uint256 availableInterest = interest.sub(withdrawnAmount[investor]);
        return availableInterest;
    }

    function canWithdraw(address investor) public view returns (bool) {
        return lastInvestmentTime[investor] > 0;
    }

    function withdraw() public {
        require(lastInvestmentTime[msg.sender] > 0);
        require(now > lastInvestmentTime[msg.sender]);

        uint256 interest = calculateInterest(msg.sender);
        uint256 availableBalance = investments[msg.sender].mul(totalWithdrawn[msg.sender]).div(MAX_DAILY_WITHDRAWAL);
        uint256 totalAvailable = availableBalance.sub(totalWithdrawn[msg.sender]);

        if (interest > 0) {
            withdrawnAmount[msg.sender] = withdrawnAmount[msg.sender].add(interest);
            msg.sender.transfer(interest);
            emit Withdraw(msg.sender, interest);
        }
    }

    function withdrawShare() public {
        require(lastInvestmentTime[msg.sender] > 0);
        require(now > lastInvestmentTime[msg.sender]);

        uint256 availableBalance = investments[msg.sender].mul(totalWithdrawn[msg.sender]).div(MAX_DAILY_WITHDRAWAL);
        uint256 totalAvailable = availableBalance.sub(totalWithdrawn[msg.sender]);

        if (totalAvailable > 0) {
            totalWithdrawn[msg.sender] = totalWithdrawn[msg.sender].add(totalAvailable);
            msg.sender.transfer(totalAvailable);
            emit WithdrawShare(msg.sender, totalAvailable);
        }
    }

    function claimBounty() public {
        uint256 reward = referralRewards[msg.sender];
        if (reward >= MINIMUM_INVESTMENT) {
            if (address(this).balance > reward) {
                referralRewards[msg.sender] = 0;
                msg.sender.transfer(reward);
                emit Bounty(msg.sender, reward);
            }
        }
    }

    function getInterest(address investor) public view returns (uint256) {
        return calculateInterest(investor);
    }

    function getWithdrawnAmount(address investor) public view returns (uint256) {
        return withdrawnAmount[investor];
    }

    function getTotalWithdrawn(address investor) public view returns (uint256) {
        return totalWithdrawn[investor];
    }

    function getInvestment(address investor) public view returns (uint256) {
        return investments[investor];
    }

    function getReferralReward(address referrer) public view returns (uint256) {
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