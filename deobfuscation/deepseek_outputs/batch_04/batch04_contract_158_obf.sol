```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public investorBalance;
    mapping(address => uint256) public lastActionTime;
    mapping(address => uint256) public totalWithdrawn;
    
    uint256 public totalInvestors;
    uint256 public totalInvested;
    
    address public owner = 0x84B7EEB9b876fB522Ea39e6201652Da11298A5fF;
    uint256 public feePercent = 20;
    uint256 public stepTime = 1 hours;
    uint256 public minDeposit = 0.001 ether;
    
    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    
    modifier onlyInvestor() {
        require(investorBalance[msg.sender] > 0, "Address not found");
        _;
    }
    
    modifier checkActionTime() {
        require(now >= lastActionTime[msg.sender].add(stepTime), "Too fast withdrawal request");
        _;
    }
    
    function collectPercent() onlyInvestor checkActionTime internal {
        uint256 payout = calculatePayout();
        
        if (investorBalance[msg.sender].mul(2) <= totalWithdrawn[msg.sender]) {
            investorBalance[msg.sender] = 0;
            lastActionTime[msg.sender] = 0;
            totalWithdrawn[msg.sender] = 0;
        } else {
            lastActionTime[msg.sender] = now;
            totalWithdrawn[msg.sender] = totalWithdrawn[msg.sender].add(payout);
            msg.sender.transfer(payout);
            emit Withdraw(msg.sender, payout);
        }
    }
    
    function getDailyPercent() public view returns(uint256) {
        uint256 contractBalance = address(this).balance;
        
        if (contractBalance < 1000 ether) {
            return 250;
        } else if (contractBalance >= 1000 ether && contractBalance < 2500 ether) {
            return 300;
        } else if (contractBalance >= 2500 ether && contractBalance < 5000 ether) {
            return 350;
        } else if (contractBalance >= 5000 ether) {
            return 375;
        }
    }
    
    function calculatePayout() public view returns(uint256) {
        uint256 dailyPercent = getDailyPercent();
        uint256 dailyProfit = investorBalance[msg.sender].mul(dailyPercent).div(100000);
        uint256 timePassed = now.sub(lastActionTime[msg.sender]);
        uint256 periodsPassed = timePassed.div(stepTime);
        return dailyProfit.mul(periodsPassed);
    }
    
    function deposit() private {
        if (msg.value > 0) {
            if (investorBalance[msg.sender] == 0) {
                totalInvestors = totalInvestors.add(1);
            }
            
            if (investorBalance[msg.sender] > 0 && now > lastActionTime[msg.sender].add(stepTime)) {
                collectPercent();
            }
            
            investorBalance[msg.sender] = investorBalance[msg.sender].add(msg.value);
            lastActionTime[msg.sender] = now;
            totalInvested = totalInvested.add(msg.value);
            
            owner.transfer(msg.value.mul(feePercent).div(100));
            emit Invest(msg.sender, msg.value);
        } else {
            collectPercent();
        }
    }
    
    function() external payable {
        deposit();
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