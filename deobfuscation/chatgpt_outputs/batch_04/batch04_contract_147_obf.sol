pragma solidity ^0.4.25;

contract InvestmentContract {
    using SafeMath for uint256;

    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public pendingWithdrawals;

    uint256 public minimumInvestment = 10000000000000000; // 0.01 ETH
    uint256 public interestRate = 100; // 1% interest rate
    address public owner;
    address public bountyManager;

    event Withdraw(address indexed user, uint256 amount);
    event Bounty(address indexed user, uint256 amount);

    constructor(address _bountyManager) public {
        owner = msg.sender;
        bountyManager = _bountyManager;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBountyManager() {
        require(msg.sender == bountyManager);
        _;
    }

    function() external payable {
        require(msg.value >= minimumInvestment);

        if (userBalances[msg.sender] > 0) {
            if (withdraw()) {
                pendingWithdrawals[msg.sender] = 0;
            }
        }

        userBalances[msg.sender] = userBalances[msg.sender].add(msg.value);
        lastInvestmentTime[msg.sender] = block.timestamp;

        owner.transfer(msg.value.mul(95).div(100));
        bountyManager.transfer(msg.value.mul(5).div(100));

        emit Bounty(msg.sender, msg.value);
    }

    function calculateInterest(address user) public view returns (uint256) {
        uint256 timeElapsed = now.sub(lastInvestmentTime[user]).div(1 minutes);
        uint256 interest = userBalances[user].mul(interestRate).div(100);
        uint256 totalInterest = interest.mul(timeElapsed).div(72000);
        uint256 availableInterest = totalInterest.sub(pendingWithdrawals[user]);
        return availableInterest;
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

    function getPendingWithdrawals() public view returns (uint256) {
        return calculateInterest(msg.sender);
    }

    function getUserPendingWithdrawals(address user) public view returns (uint256) {
        return pendingWithdrawals[user];
    }

    function getUserBalance(address user) public view returns (uint256) {
        return userBalances[user];
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