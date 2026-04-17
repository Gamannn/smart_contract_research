```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public investmentAmounts;
    mapping(address => uint256) public investmentTimestamps;
    mapping(address => uint256) public withdrawnAmounts;
    mapping(address => uint256) public referralRewards;
    
    uint256 public totalInvestors;
    uint256 public minimumInvestment = 0.01 ether;
    uint256 public startTime;
    
    address public owner;
    address public wallet;
    
    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed referrer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
        wallet = msg.sender;
        startTime = now;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner, address newWallet) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        wallet = newWallet;
    }
    
    function() public payable {
        invest(address(0));
    }
    
    function invest(address referrer) public payable {
        require(msg.value >= minimumInvestment);
        
        address investor = msg.sender;
        
        if (referrer != address(0) && 
            referrer != investor && 
            deposits[referrer] >= 0.25 ether) {
            referralRewards[referrer] = referralRewards[referrer].add(
                msg.value.mul(5).div(100)
            );
        }
        
        if (deposits[msg.sender] > 0) {
            if (withdraw()) {
                withdrawnAmounts[msg.sender] = 0;
            }
        }
        
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        investmentAmounts[msg.sender] = msg.value;
        investmentTimestamps[msg.sender] = block.timestamp;
        
        wallet.transfer(msg.value.mul(5).div(100));
        
        emit Invest(msg.sender, msg.value);
    }
    
    function calculateDividends(address investor) public view returns (uint256) {
        uint256 minutesPassed = now.sub(investmentTimestamps[investor]).div(1 minutes);
        
        if (minutesPassed < 4321) {
            uint256 dailyPercent = investmentAmounts[investor].mul(50).div(100);
            uint256 dividends = dailyPercent.mul(minutesPassed).div(1440);
            uint256 balance = dividends.sub(withdrawnAmounts[investor]);
            return balance;
        } else {
            uint256 maxReturn = investmentAmounts[investor].mul(150).div(100);
            uint256 balance = maxReturn.sub(withdrawnAmounts[investor]);
            return balance;
        }
    }
    
    function getMinutesPassed(address investor) public view returns (uint256) {
        uint256 minutesPassed = now.sub(investmentTimestamps[investor]).div(1 minutes);
        return minutesPassed;
    }
    
    function withdraw() public returns (bool) {
        require(investmentTimestamps[msg.sender] > 0);
        
        uint256 dividends = calculateDividends(msg.sender);
        
        if (address(this).balance > dividends) {
            if (dividends > 0) {
                withdrawnAmounts[msg.sender] = withdrawnAmounts[msg.sender].add(dividends);
                msg.sender.transfer(dividends);
                emit Withdraw(msg.sender, dividends);
            }
            return true;
        } else {
            return false;
        }
    }
    
    function claimBounty() public {
        uint256 referralBonus = checkReferralBonus(msg.sender);
        
        if (referralBonus >= minimumInvestment) {
            if (address(this).balance > referralBonus) {
                referralRewards[msg.sender] = 0;
                msg.sender.transfer(referralBonus);
                emit Bounty(msg.sender, referralBonus);
            }
        }
    }
    
    function checkReferralBonus(address referrer) public view returns (uint256) {
        return referralRewards[referrer];
    }
    
    function checkDividends() public view returns (uint256) {
        return calculateDividends(msg.sender);
    }
    
    function getWithdrawnAmount(address investor) public view returns (uint256) {
        return withdrawnAmounts[investor];
    }
    
    function getDeposit(address investor) public view returns (uint256) {
        return deposits[investor];
    }
    
    function getInvestmentAmount(address investor) public view returns (uint256) {
        return investmentAmounts[investor];
    }
    
    function getReferralReward(address referrer) public view returns (uint256) {
        return referralRewards[referrer];
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