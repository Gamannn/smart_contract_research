pragma solidity ^0.4.24;

contract StakingContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public investments;
    mapping(address => uint256) public investmentTime;
    mapping(address => uint256) public withdrawn;
    mapping(address => uint256) public referralBalance;
    
    address public owner;
    uint256 public minimumInvestment = 0.01 ether;
    uint256 public referralThreshold = 2 ether;
    uint256 public dailyPercent = 10;
    uint256 public referralPercent = 5;
    uint256 public secondsInDay = 86400;
    uint256 public secondsInMinute = 60;
    
    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed referrer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
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
    
    function() public payable {
        invest(address(0));
    }
    
    function invest(address referrer) public payable {
        require(msg.value >= minimumInvestment);
        
        address investor = msg.sender;
        
        if (referrer != address(0) && investments[referrer] >= referralThreshold) {
            uint256 referralReward = msg.value.mul(referralPercent).div(100);
            referralBalance[referrer] = referralBalance[referrer].add(referralReward);
        }
        
        if (investments[investor] > 0) {
            if (calculateDividends(investor) > 0) {
                withdrawn[investor] = 0;
            }
        }
        
        investments[investor] = investments[investor].add(msg.value);
        investmentTime[investor] = block.timestamp;
        
        emit Invest(investor, msg.value);
    }
    
    function calculateDividends(address investor) public view returns (uint256) {
        uint256 timePassed = now.sub(investmentTime[investor]).div(1 minutes);
        uint256 dailyReturn = investments[investor].mul(dailyPercent).div(100);
        uint256 dividends = dailyReturn.mul(timePassed).div(1440);
        uint256 pending = dividends.sub(withdrawn[investor]);
        return pending;
    }
    
    function withdrawDividends() public returns (bool) {
        require(investmentTime[msg.sender] > 0);
        
        uint256 dividends = calculateDividends(msg.sender);
        
        if (address(this).balance > dividends) {
            if (dividends > 0) {
                withdrawn[msg.sender] = withdrawn[msg.sender].add(dividends);
                msg.sender.transfer(dividends);
                emit Withdraw(msg.sender, dividends);
            }
            return true;
        } else {
            return false;
        }
    }
    
    function withdrawBounty() public {
        uint256 bounty = referralBalance[msg.sender];
        
        if (bounty >= minimumInvestment) {
            if (address(this).balance > bounty) {
                referralBalance[msg.sender] = 0;
                msg.sender.transfer(bounty);
                emit Bounty(msg.sender, bounty);
            }
        }
    }
    
    function getDividends() public view returns (uint256) {
        return calculateDividends(msg.sender);
    }
    
    function getWithdrawn(address investor) public view returns (uint256) {
        return withdrawn[investor];
    }
    
    function getInvestment(address investor) public view returns (uint256) {
        return investments[investor];
    }
    
    function getReferralBalance(address referrer) public view returns (uint256) {
        return referralBalance[referrer];
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