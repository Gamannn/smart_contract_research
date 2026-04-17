```solidity
pragma solidity ^0.4.24;

contract Pyramid {
    using SafeMath for uint256;
    
    mapping(address => uint256) public investments;
    mapping(address => uint256) public investmentTimestamps;
    mapping(address => uint256) public totalWithdrawals;
    mapping(address => uint256) public referralBonuses;
    
    uint256 public currentStep = 1;
    
    address public owner;
    address public dividendAddress = 0x31B35eC3FA75FA37416BF1A06f7e8e4880C44F49;
    uint256 public minimumInvestment = 10 finney;
    uint256 public stakingRequirement = 2000000000000000000;
    
    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed referrer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Invest(address indexed investor, uint256 amount);
    
    constructor() public {
        owner = msg.sender;
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
        invest(address(0));
    }
    
    function invest(address referrer) public payable {
        require(msg.value >= minimumInvestment);
        
        if(referrer != address(0) && investments[referrer] >= stakingRequirement) {
            referralBonuses[referrer] = referralBonuses[referrer].add(msg.value.mul(5).div(100));
        }
        
        if (investments[msg.sender] > 0) {
            if (calculateDividends(msg.sender) > 0) {
                totalWithdrawals[msg.sender] = 0;
            }
        }
        
        investments[msg.sender] = investments[msg.sender].add(msg.value);
        investmentTimestamps[msg.sender] = block.timestamp;
        
        dividendAddress.transfer(msg.value.mul(5).div(100));
        
        emit Invest(msg.sender, msg.value);
    }
    
    function calculateDividends(address investor) public view returns (uint256) {
        uint256 minutesPassed = now.sub(investmentTimestamps[investor]).div(1 minutes);
        uint256 dailyRate = investments[investor].mul(currentStep).div(100);
        uint256 dividends = dailyRate.mul(minutesPassed).div(1440);
        uint256 availableDividends = dividends.sub(totalWithdrawals[investor]);
        
        return availableDividends;
    }
    
    function withdraw() public returns (bool) {
        require(investmentTimestamps[msg.sender] > 0);
        
        uint256 dividends = calculateDividends(msg.sender);
        
        if (address(this).balance > dividends) {
            if (dividends > 0) {
                totalWithdrawals[msg.sender] = totalWithdrawals[msg.sender].add(dividends);
                msg.sender.transfer(dividends);
                emit Withdraw(msg.sender, dividends);
            }
            return true;
        } else {
            return false;
        }
    }
    
    function claimBounty() public {
        uint256 bounty = referralBonuses[msg.sender];
        
        if(bounty >= minimumInvestment) {
            if (address(this).balance > bounty) {
                referralBonuses[msg.sender] = 0;
                msg.sender.transfer(bounty);
                emit Bounty(msg.sender, bounty);
            }
        }
    }
    
    function myDividends() public view returns (uint256) {
        return calculateDividends(msg.sender);
    }
    
    function getTotalWithdrawals(address investor) public view returns (uint256) {
        return totalWithdrawals[investor];
    }
    
    function getInvestment(address investor) public view returns (uint256) {
        return investments[investor];
    }
    
    function getReferralBonus(address referrer) public view returns (uint256) {
        return referralBonuses[referrer];
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