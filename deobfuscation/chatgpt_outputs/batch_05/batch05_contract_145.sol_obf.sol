```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint256;

    mapping(address => uint256) public investments;
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public withdrawals;
    mapping(address => uint256) public bounties;

    uint256 public constant MINIMUM_INVESTMENT = 10 finney;
    address public owner;
    address public dividendAddress;

    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed hunter, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Invest(address indexed investor, uint256 amount);

    constructor() public {
        owner = msg.sender;
        dividendAddress = 0x31B35eC3FA75FA37416BF1A06f7e8e4880C44F49;
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

    function () public payable {
        invest(0x0);
    }

    function invest(address referrer) public payable {
        require(msg.value >= MINIMUM_INVESTMENT);
        address investor = msg.sender;

        if (referrer != address(0) && investments[referrer] >= 2 ether) {
            bounties[referrer] = bounties[referrer].add(msg.value.mul(5).div(100));
        }

        if (investments[investor] > 0) {
            if (canWithdraw()) {
                withdrawals[investor] = 0;
            }
        }

        investments[investor] = investments[investor].add(msg.value);
        lastInvestmentTime[investor] = block.timestamp;

        dividendAddress.transfer(msg.value.mul(5).div(100));
        emit Invest(investor, msg.value);
    }

    function calculateReward(address investor) view public returns (uint256) {
        uint256 timeElapsed = now.sub(lastInvestmentTime[investor]).div(1 minutes);
        uint256 reward = investments[investor].mul(1).div(100);
        uint256 maxReward = timeElapsed.mul(1440).div(1);
        uint256 availableReward = maxReward.sub(withdrawals[investor]);
        return availableReward;
    }

    function canWithdraw() public returns (bool) {
        require(lastInvestmentTime[msg.sender] > 0);
        uint256 reward = calculateReward(msg.sender);

        if (address(this).balance > reward) {
            if (reward > 0) {
                withdrawals[msg.sender] = withdrawals[msg.sender].add(reward);
                msg.sender.transfer(reward);
                emit Withdraw(msg.sender, reward);
            }
            return true;
        } else {
            return false;
        }
    }

    function claimBounty() public {
        uint256 bounty = bounties[msg.sender];
        if (bounty >= MINIMUM_INVESTMENT) {
            if (address(this).balance > bounty) {
                bounties[msg.sender] = 0;
                msg.sender.transfer(bounty);
                emit Bounty(msg.sender, bounty);
            }
        }
    }

    function getReward() public view returns (uint256) {
        return calculateReward(msg.sender);
    }

    function getWithdrawals(address investor) public view returns (uint256) {
        return withdrawals[investor];
    }

    function getInvestments(address investor) public view returns (uint256) {
        return investments[investor];
    }

    function getBounties(address hunter) public view returns (uint256) {
        return bounties[hunter];
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