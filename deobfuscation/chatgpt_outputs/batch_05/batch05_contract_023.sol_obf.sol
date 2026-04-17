```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint256;

    mapping(address => uint256) public investments;
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public dividends;
    mapping(address => uint256) public bounties;

    uint256 public minimumInvestment = 10000000000000000;
    address public owner;
    address public promoter;
    address public ownerWallet;

    event Bounty(address indexed investor, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);

    constructor(address _ownerWallet) public {
        owner = msg.sender;
        ownerWallet = _ownerWallet;
        promoter = 0xf8EeAe7abe051A0B7a4ec5758af411F870A8Add3;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPromoter() {
        require(msg.sender == promoter);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function () external payable {
        require(msg.value >= minimumInvestment);

        if (investments[msg.sender] > 0) {
            uint256 dividend = calculateDividend(msg.sender);
            if (dividend > 0) {
                dividends[msg.sender] = 0;
                msg.sender.transfer(dividend);
            }
        }

        investments[msg.sender] = investments[msg.sender].add(msg.value);
        lastInvestmentTime[msg.sender] = block.timestamp;

        ownerWallet.transfer(msg.value.mul(1000).div(1000).mul(5).div(100));
        promoter.transfer(msg.value.mul(1000).div(1000).mul(5).div(100));

        emit Invest(msg.sender, msg.value);
    }

    function calculateDividend(address investor) public view returns (uint256) {
        uint256 timeElapsed = now.sub(lastInvestmentTime[investor]).div(1 minutes);
        uint256 dailyRate = investments[investor].mul(3).div(100).div(1440);
        uint256 dividend = dailyRate.mul(timeElapsed).sub(dividends[investor]);
        return dividend;
    }

    function withdrawDividends() public returns (bool) {
        require(lastInvestmentTime[msg.sender] > 0);

        uint256 dividend = calculateDividend(msg.sender);
        if (address(this).balance > dividend) {
            if (dividend > 0) {
                dividends[msg.sender] = dividends[msg.sender].add(dividend);
                msg.sender.transfer(dividend);
                emit Withdraw(msg.sender, dividend);
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

    function calculateBounty(address investor) public view returns (uint256) {
        return calculateDividend(investor);
    }

    function getDividends(address investor) public view returns (uint256) {
        return dividends[investor];
    }

    function getInvestments(address investor) public view returns (uint256) {
        return investments[investor];
    }

    function getBounties(address investor) public view returns (uint256) {
        return bounties[investor];
    }

    function setBounty(address investor, uint256 amount) public onlyPromoter {
        bounties[investor] = bounties[investor].add(amount);
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