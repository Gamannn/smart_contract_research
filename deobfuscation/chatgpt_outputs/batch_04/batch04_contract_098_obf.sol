pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint256;

    mapping(address => uint256) private investments;
    mapping(address => uint256) private lastInvestmentTime;
    mapping(address => uint256) private withdrawnAmounts;
    mapping(address => uint256) private bountyAmounts;

    uint256 public minimumInvestment = 10000000000000000;
    address public owner;
    address public ownerWallet;
    address public bountyManager;

    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _ownerWallet) public {
        owner = msg.sender;
        ownerWallet = _ownerWallet;
        bountyManager = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBountyManager() {
        require(msg.sender == bountyManager);
        _;
    }

    function transferOwnership(address newOwner, address newOwnerWallet) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        ownerWallet = newOwnerWallet;
    }

    function () external payable {
        require(msg.value >= minimumInvestment);

        if (investments[msg.sender] > 0) {
            if (canWithdraw()) {
                withdrawnAmounts[msg.sender] = 0;
            }
        }

        investments[msg.sender] = investments[msg.sender].add(msg.value);
        lastInvestmentTime[msg.sender] = block.timestamp;

        ownerWallet.transfer(msg.value.mul(95).div(100));

        emit Invest(msg.sender, msg.value);
    }

    function calculateProfit(address investor) view public returns (uint256) {
        uint256 timeElapsed = now.sub(lastInvestmentTime[investor]).div(1 minutes);
        uint256 profit = investments[investor].mul(4).mul(timeElapsed).div(1440);
        uint256 balance = withdrawnAmounts[investor];
        return balance.add(profit);
    }

    function canWithdraw() public returns (bool) {
        require(lastInvestmentTime[msg.sender] > 0);

        uint256 profit = calculateProfit(msg.sender);

        if (address(this).balance > profit) {
            if (profit > 0) {
                withdrawnAmounts[msg.sender] = withdrawnAmounts[msg.sender].add(profit);
                msg.sender.transfer(profit);
                emit Withdraw(msg.sender, profit);
            }
            return true;
        } else {
            return false;
        }
    }

    function claimBounty() public {
        uint256 bountyBalance = bountyAmounts[msg.sender];

        if (bountyBalance >= minimumInvestment) {
            if (address(this).balance > bountyBalance) {
                bountyAmounts[msg.sender] = 0;
                msg.sender.transfer(bountyBalance);
                emit Bounty(msg.sender, bountyBalance);
            }
        }
    }

    function getProfit() public view returns (uint256) {
        return calculateProfit(msg.sender);
    }

    function getWithdrawnAmount(address investor) public view returns (uint256) {
        return withdrawnAmounts[investor];
    }

    function getInvestment(address investor) public view returns (uint256) {
        return investments[investor];
    }

    function getBountyAmount(address investor) public view returns (uint256) {
        return bountyAmounts[investor];
    }

    function addBounty(address investor, uint256 amount) public onlyBountyManager {
        bountyAmounts[investor] = bountyAmounts[investor].add(amount);
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