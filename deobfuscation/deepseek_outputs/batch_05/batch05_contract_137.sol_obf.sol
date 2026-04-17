```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public investments;
    mapping(address => uint256) public investmentTimestamps;
    mapping(address => uint256) public dividendsPaid;
    mapping(address => uint256) public referralBonuses;
    
    address public owner;
    address public ownerWallet;
    uint256 public minimumInvestment = 0.01 ether;
    uint256 public dailyPercent = 2;
    uint256 public referralPercent = 10;
    uint256 public bountyPercent = 5;
    uint256 public minutesInDay = 1440;
    
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
    
    function () public payable {
        invest(address(0));
    }
    
    function invest(address referrer) public payable {
        require(msg.value >= minimumInvestment);
        
        address investor = msg.sender;
        
        if (referrer != address(0) && investments[referrer] >= minimumInvestment) {
            referralBonuses[referrer] = referralBonuses[referrer].add(
                msg.value.mul(referralPercent).div(100)
            );
        }
        
        if (investments[msg.sender] > 0) {
            if (withdrawDividends()) {
                dividendsPaid[msg.sender] = 0;
            }
        }
        
        investments[msg.sender] = investments[msg.sender].add(msg.value);
        investmentTimestamps[msg.sender] = block.timestamp;
        
        ownerWallet.transfer(msg.value.mul(bountyPercent).div(100));
        
        emit Invest(msg.sender, msg.value);
    }
    
    function calculateDividends(address investor) public view returns (uint256) {
        uint256 minutesPassed = now.sub(investmentTimestamps[investor]).div(1 minutes);
        uint256 dailyIncome = investments[investor].mul(dailyPercent).div(100);
        uint256 dividends = dailyIncome.mul(minutesPassed).div(minutesInDay);
        uint256 pendingDividends = dividends.sub(dividendsPaid[investor]);
        
        return pendingDividends;
    }
    
    function withdrawDividends() public returns (bool) {
        require(investmentTimestamps[msg.sender] > 0);
        
        uint256 dividends = calculateDividends(msg.sender);
        
        if (address(this).balance >= dividends) {
            if (dividends > 0) {
                dividendsPaid[msg.sender] = dividendsPaid[msg.sender].add(dividends);
                msg.sender.transfer(dividends);
                emit Withdraw(msg.sender, dividends);
            }
            return true;
        } else {
            return false;
        }
    }
    
    function claimBounty() public {
        uint256 bountyAmount = checkReferral(msg.sender);
        
        if (bountyAmount >= minimumInvestment) {
            if (address(this).balance >= bountyAmount) {
                referralBonuses[msg.sender] = 0;
                msg.sender.transfer(bountyAmount);
                emit Bounty(msg.sender, bountyAmount);
            }
        }
    }
    
    function checkReferral(address referrer) public view returns (uint256) {
        return referralBonuses[referrer];
    }
    
    function getPendingDividends() public view returns (uint256) {
        return calculateDividends(msg.sender);
    }
    
    function getDividendsPaid(address investor) public view returns (uint256) {
        return dividendsPaid[investor];
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