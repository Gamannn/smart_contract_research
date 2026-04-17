pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint256;

    mapping(address => uint256) public investments;
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public referralRewards;
    mapping(address => uint256) public withdrawnRewards;
    mapping(address => uint256) public referralCount;

    uint256 public minimumInvestment;
    uint256 public referralBonus;
    uint256 public rewardRate;
    address public owner;
    address public feeReceiver;

    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed referrer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        feeReceiver = msg.sender;
        minimumInvestment = 0.25 ether;
        referralBonus = 10 finney;
        rewardRate = 50;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function() public payable {
        invest(0x0);
    }

    function invest(address referrer) public payable {
        require(msg.value >= minimumInvestment);

        address investor = msg.sender;

        if (referrer != address(0) && referrer != investor && investments[referrer] >= referralBonus) {
            uint256 referralReward = msg.value.mul(5).div(100);
            referralRewards[referrer] = referralRewards[referrer].add(referralReward);
        }

        if (investments[investor] > 0) {
            if (withdrawRewards()) {
                withdrawnRewards[investor] = 0;
            }
        }

        investments[investor] = investments[investor].add(msg.value);
        lastInvestmentTime[investor] = block.timestamp;

        uint256 fee = msg.value.mul(5).div(100);
        feeReceiver.transfer(fee);

        emit Invest(investor, msg.value);
    }

    function calculateReward(address investor) view public returns (uint256) {
        uint256 timeElapsed = now.sub(lastInvestmentTime[investor]).div(1 minutes);
        if (timeElapsed < 4321) {
            uint256 reward = investments[investor].mul(rewardRate).div(100).mul(timeElapsed).div(1440);
            uint256 totalReward = reward.sub(withdrawnRewards[investor]);
            return totalReward;
        } else {
            uint256 reward = investments[investor].mul(150).div(100);
            uint256 totalReward = reward.sub(withdrawnRewards[investor]);
            return totalReward;
        }
    }

    function getTimeElapsed(address investor) view public returns (uint256) {
        uint256 timeElapsed = now.sub(lastInvestmentTime[investor]).div(1 minutes);
        return timeElapsed;
    }

    function withdrawRewards() public returns (bool) {
        require(lastInvestmentTime[msg.sender] > 0);

        uint256 reward = calculateReward(msg.sender);
        if (address(this).balance > reward) {
            if (reward > 0) {
                withdrawnRewards[msg.sender] = withdrawnRewards[msg.sender].add(reward);
                msg.sender.transfer(reward);
                emit Withdraw(msg.sender, reward);
            }
            return true;
        } else {
            return false;
        }
    }

    function claimReferralBonus() public {
        uint256 referralBonusAmount = calculateReward(msg.sender);
        if (referralBonusAmount >= minimumInvestment) {
            if (address(this).balance > referralBonusAmount) {
                referralRewards[msg.sender] = 0;
                msg.sender.transfer(referralBonusAmount);
                emit Bounty(msg.sender, referralBonusAmount);
            }
        }
    }

    function getReward(address investor) public view returns (uint256) {
        return calculateReward(investor);
    }

    function getWithdrawnRewards(address investor) public view returns (uint256) {
        return withdrawnRewards[investor];
    }

    function getInvestments(address investor) public view returns (uint256) {
        return investments[investor];
    }

    function getReferralRewards(address investor) public view returns (uint256) {
        return referralRewards[investor];
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