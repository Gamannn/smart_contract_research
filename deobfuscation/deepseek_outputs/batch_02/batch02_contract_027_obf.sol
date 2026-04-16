```solidity
pragma solidity ^0.4.25;

contract InvestmentContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public investments;
    mapping(address => uint256) public investmentTime;
    mapping(address => uint256) public dividendsWithdrawn;
    mapping(address => uint256) public referralBonuses;
    mapping(address => uint256) public sharesWithdrawn;
    
    uint256 public totalInvestments;
    uint256 public totalDividends;
    uint256 public contractBalance;
    
    address public owner;
    address public marketingWallet;
    
    uint256 public constant MIN_INVESTMENT = 10 finney;
    uint256 public constant MIN_WITHDRAWAL = 2 ether;
    uint256 public constant DAILY_PERCENT = 5;
    uint256 public constant REFERRAL_PERCENT = 5;
    uint256 public constant PERCENT_DIVISOR = 100;
    uint256 public constant DAYS_IN_MONTH = 30;
    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public constant SECONDS_IN_MINUTE = 60;
    
    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event WithdrawShare(address indexed investor, uint256 amount);
    event Bounty(address indexed referrer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address _owner, address _marketingWallet) public {
        require(_owner != address(0));
        owner = _owner;
        marketingWallet = _marketingWallet;
    }
    
    function transferOwnership(address newOwner, address newMarketingWallet) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        marketingWallet = newMarketingWallet;
    }
    
    function() public payable {
        invest(address(0));
    }
    
    function invest(address referrer) public payable {
        require(msg.value >= MIN_INVESTMENT);
        
        address investor = msg.sender;
        
        if(referrer != address(0) && referrer != investor) {
            referralBonuses[referrer] = referralBonuses[referrer].add(msg.value.mul(REFERRAL_PERCENT).div(PERCENT_DIVISOR));
        }
        
        if(investments[investor] > 0) {
            if(calculateDividends(investor) > 0) {
                dividendsWithdrawn[investor] = 0;
            }
        }
        
        investments[investor] = investments[investor].add(msg.value);
        investmentTime[investor] = now;
        
        marketingWallet.transfer(msg.value.mul(REFERRAL_PERCENT).div(PERCENT_DIVISOR));
        
        totalDividends = totalDividends.add(msg.value.mul(DAILY_PERCENT).div(PERCENT_DIVISOR));
        totalInvestments = totalInvestments.add(msg.value);
        contractBalance = contractBalance.add(msg.value);
        
        emit Invest(investor, msg.value);
    }
    
    function calculateDividends(address investor) public view returns(uint256) {
        uint256 timePassed = now.sub(investmentTime[investor]).div(SECONDS_IN_MINUTE);
        uint256 dailyReturn = investments[investor].mul(DAILY_PERCENT).div(PERCENT_DIVISOR);
        uint256 totalDividend = dailyReturn.mul(timePassed).div(DAYS_IN_MONTH);
        uint256 availableDividend = totalDividend.sub(dividendsWithdrawn[investor]);
        return availableDividend;
    }
    
    function withdrawDividends() public returns(bool) {
        require(investmentTime[msg.sender] > 0);
        
        uint256 dividendAmount = calculateDividends(msg.sender);
        
        if(address(this).balance > dividendAmount && dividendAmount <= address(this).balance.sub(contractBalance)) {
            if(dividendAmount > 0) {
                dividendsWithdrawn[msg.sender] = dividendsWithdrawn[msg.sender].add(dividendAmount);
                msg.sender.transfer(dividendAmount);
                emit Withdraw(msg.sender, dividendAmount);
                return true;
            }
        }
        return false;
    }
    
    function withdrawShares() public {
        require(investmentTime[msg.sender] > 0);
        require(MIN_WITHDRAWAL < now);
        
        uint256 totalShare = contractBalance.mul(investments[msg.sender]).div(totalInvestments);
        uint256 alreadyWithdrawn = sharesWithdrawn[msg.sender];
        
        if(totalShare <= alreadyWithdrawn) {
            return;
        }
        
        uint256 shareAmount = totalShare.sub(alreadyWithdrawn);
        
        if(shareAmount > 0) {
            sharesWithdrawn[msg.sender] = alreadyWithdrawn.add(shareAmount);
            contractBalance = contractBalance.sub(shareAmount);
            msg.sender.transfer(shareAmount);
            emit WithdrawShare(msg.sender, shareAmount);
        }
    }
    
    function claimBounty() public {
        uint256 bountyAmount = referralBonuses[msg.sender];
        
        if(bountyAmount >= MIN_WITHDRAWAL) {
            if(address(this).balance > bountyAmount) {
                referralBonuses[msg.sender] = 0;
                msg.sender.transfer(bountyAmount);
                emit Bounty(msg.sender, bountyAmount);
            }
        }
    }
    
    function getDividends() public view returns(uint256) {
        return calculateDividends(msg.sender);
    }
    
    function getDividendsWithdrawn(address investor) public view returns(uint256) {
        return dividendsWithdrawn[investor];
    }
    
    function getSharesWithdrawn(address investor) public view returns(uint256) {
        return sharesWithdrawn[investor];
    }
    
    function calculateShares(address investor) public view returns(uint256) {
        uint256 totalShare = contractBalance.mul(investments[investor]).div(totalInvestments);
        uint256 alreadyWithdrawn = sharesWithdrawn[investor];
        
        if(totalShare <= alreadyWithdrawn) {
            return 0;
        } else {
            return totalShare.sub(alreadyWithdrawn);
        }
    }
    
    function getInvestment(address investor) public view returns(uint256) {
        return investments[investor];
    }
    
    function getReferralBonus(address referrer) public view returns(uint256) {
        return referralBonuses[referrer];
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
```