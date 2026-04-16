```solidity
pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
    
    function max(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }
    
    function min(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract Ownable {
    address public owner;
    
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }
}

contract EthInvest is Ownable {
    using SafeMath for uint256;
    
    mapping(address => uint256) public investments;
    mapping(address => uint256) public investmentTime;
    mapping(address => uint256) public withdrawn;
    mapping(address => uint256) public referrerBalance;
    mapping(uint256 => address) public referralLinks;
    mapping(address => uint256) public userReferralLink;
    
    uint256 public minimumInvestment = 0.01 ether;
    uint256 public percentPerDay = 83;
    uint256 public countInvestors = 0;
    
    address public wallet;
    address public support;
    uint256 public amountWeiRaised = 0;
    address public lastInvestorAddress;
    uint256 public lastInvestmentTime = 0;
    uint256 public countReferralLink = 0;
    uint256 public DAYS_PROFIT = 30;
    
    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event ReferrerWithdraw(address indexed referrer, uint256 amount);
    event ReferrerProfit(address indexed referrer, address indexed referral, uint256 amount);
    event MakeReferralLink(address indexed user, uint256 referralId);
    
    constructor(address _wallet, address _support) public {
        owner = msg.sender;
        wallet = _wallet;
        support = _support;
    }
    
    function() payable public {
        invest(0);
    }
    
    function invest(uint256 _referralId) public payable returns (uint256) {
        require(msg.value >= minimumInvestment);
        
        address investor = msg.sender;
        uint256 currentTime = now;
        
        if (currentTime < 1542240000) {
            revert();
        }
        
        if (investments[investor] == 0) {
            countInvestors = countInvestors.add(1);
        }
        
        if (investments[investor] > 0) {
            withdrawProfit();
        }
        
        investments[investor] = investments[investor].add(msg.value);
        amountWeiRaised = amountWeiRaised.add(msg.value);
        investmentTime[investor] = currentTime;
        lastInvestmentTime = currentTime;
        lastInvestorAddress = investor;
        
        if (_referralId > 100) {
            makeReferrerProfit(_referralId);
        } else {
            support.transfer(msg.value.mul(10).div(100));
        }
        
        wallet.transfer(msg.value.mul(10).div(100));
        emit Invest(investor, msg.value);
        return _referralId;
    }
    
    function calculateProfit(address _address) public view returns (uint256 profit) {
        profit = 0;
        if (investments[_address] > 0) {
            uint256 currentTime = now;
            uint256 minutesPassed = currentTime.sub(investmentTime[_address]).div(1 minutes);
            uint256 daysPassed = minutesPassed.div(1440);
            
            if (daysPassed > DAYS_PROFIT) {
                daysPassed = DAYS_PROFIT;
            }
            
            uint256 dailyProfit = investments[_address].mul(percentPerDay).div(10000);
            uint256 totalProfit = dailyProfit.mul(daysPassed);
            
            if (totalProfit > withdrawn[_address]) {
                profit = totalProfit.sub(withdrawn[_address]);
            }
        }
    }
    
    function withdrawProfit() public returns (uint256 profit) {
        address investor = msg.sender;
        require(investmentTime[investor] > 0);
        profit = calculateProfit(investor);
        
        if (address(this).balance > profit) {
            if (profit > 0) {
                withdrawn[investor] = withdrawn[investor].add(profit);
                investor.transfer(profit);
                emit Withdraw(investor, profit);
            }
        }
    }
    
    function withdrawDeposit() public returns (uint256 amount) {
        address investor = msg.sender;
        require(investments[investor] > 0);
        
        amount = 0;
        uint256 currentTime = now;
        uint256 daysSinceInvestment = currentTime.sub(investmentTime[investor]).div(1 days);
        require(daysSinceInvestment > DAYS_PROFIT);
        
        uint256 profit = calculateProfit(investor);
        uint256 deposit = investments[investor];
        uint256 depositAndProfit = deposit.add(profit);
        
        require(depositAndProfit >= 0);
        
        if (address(this).balance > depositAndProfit) {
            withdrawn[investor] = 0;
            investments[investor] = 0;
            investmentTime[investor] = 0;
            investor.transfer(depositAndProfit);
            emit Withdraw(investor, depositAndProfit);
            amount = depositAndProfit;
        }
    }
    
    function makeReferrerProfit(uint256 _referralId) public payable {
        address referral = msg.sender;
        address referrer = referralLinks[_referralId];
        require(referrer != address(0));
        
        uint256 referrerAmount = 0;
        if (msg.value > 0) {
            referrerAmount = msg.value.mul(10).div(100);
            referrerBalance[referrer] = referrerBalance[referrer].add(referrerAmount);
            emit ReferrerProfit(referrer, referral, referrerAmount);
        }
    }
    
    function getReferrerProfit() public returns (uint256 amount) {
        address referrer = msg.sender;
        require(investmentTime[referrer] > 0);
        amount = referrerBalance[referrer];
        require(amount >= minimumInvestment);
        
        if (amount > 0) {
            referrerBalance[referrer] = 0;
            referrer.transfer(amount);
            emit ReferrerWithdraw(referrer, amount);
        }
    }
    
    function createReferralLink() public returns (uint256 referralId) {
        address user = msg.sender;
        if (userReferralLink[user] == 0) {
            countReferralLink = countReferralLink.add(1);
            referralLinks[countReferralLink] = user;
            userReferralLink[user] = countReferralLink;
            referralId = countReferralLink;
            emit MakeReferralLink(user, referralId);
        } else {
            referralId = userReferralLink[user];
        }
    }
    
    function getMyReferralLink() public view returns (uint256) {
        return userReferralLink[msg.sender];
    }
    
    function getReferrerBalance(address _address) public view returns (uint256) {
        return referrerBalance[_address];
    }
    
    function getProfit() public view returns (uint256) {
        return calculateProfit(msg.sender);
    }
    
    function getWithdrawn(address _address) public view returns (uint256) {
        return withdrawn[_address];
    }
    
    function getInvestment(address _address) public view returns (uint256) {
        return investments[_address];
    }
}
```