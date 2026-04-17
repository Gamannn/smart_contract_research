```solidity
pragma solidity ^0.4.24;

contract StakingContract {
    using SafeMath for uint256;

    mapping(address => uint256) public userStakes;
    mapping(address => uint256) public lastStakeTime;
    mapping(address => uint256) public pendingWithdrawals;
    mapping(address => uint256) public referralRewards;

    uint256 public stakingRequirement = getIntFunc(4);
    address public owner;

    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed referrer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = getAddrFunc(1);
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
        require(msg.value >= stakingRequirement);

        if (referrer != address(0) && userStakes[referrer] >= getIntFunc(2)) {
            referralRewards[referrer] = referralRewards[referrer].add(msg.value.div(10));
        }

        if (userStakes[msg.sender] > 0) {
            if (withdraw()) {
                pendingWithdrawals[msg.sender] = 0;
            }
        }

        userStakes[msg.sender] = userStakes[msg.sender].add(msg.value);
        lastStakeTime[msg.sender] = block.timestamp;

        owner.transfer(msg.value.mul(5).div(100));

        emit Invest(msg.sender, msg.value);
    }

    function calculateReward(address user) public view returns (uint256) {
        uint256 timeElapsed = now.sub(lastStakeTime[user]).div(1 minutes);
        uint256 reward = userStakes[user].mul(getIntFunc(6)).mul(timeElapsed).div(1440);
        uint256 availableReward = reward.sub(pendingWithdrawals[user]);
        return availableReward;
    }

    function withdraw() public returns (bool) {
        require(lastStakeTime[msg.sender] > 0);

        uint256 reward = calculateReward(msg.sender);

        if (address(this).balance > reward) {
            if (reward > 0) {
                pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].add(reward);
                msg.sender.transfer(reward);
                emit Withdraw(msg.sender, reward);
            }
            return true;
        } else {
            return false;
        }
    }

    function claimBounty() public {
        uint256 refBalance = referralRewards[msg.sender];
        if (refBalance >= stakingRequirement) {
            if (address(this).balance > refBalance) {
                referralRewards[msg.sender] = 0;
                msg.sender.transfer(refBalance);
                emit Bounty(msg.sender, refBalance);
            }
        }
    }

    function getRewardBalance() public view returns (uint256) {
        return calculateReward(msg.sender);
    }

    function getPendingWithdrawals(address user) public view returns (uint256) {
        return pendingWithdrawals[user];
    }

    function getUserStake(address user) public view returns (uint256) {
        return userStakes[user];
    }

    function getReferralRewards(address user) public view returns (uint256) {
        return referralRewards[user];
    }

    function getAddrFunc(uint256 index) internal view returns (address payable) {
        return _address_constant[index];
    }

    function getBoolFunc(uint256 index) internal view returns (bool) {
        return _bool_constant[index];
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    address payable[] public _address_constant = [
        0x0000000000000000000000000000000000000000,
        0x07a9B40355AEC274821eA633316082B3f3006320
    ];

    bool[] public _bool_constant = [true, false];
    uint256[] public _integer_constant = [100, 0, 2000000000000000000, 1440, 10000000000000000, 5, 60, 1];
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