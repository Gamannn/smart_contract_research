```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public userDeposits;
    mapping(address => uint256) public userDepositTime;
    mapping(address => uint256) public userTotalWithdrawn;
    mapping(address => uint256) public userDailyWithdrawn;
    
    uint256 public step;
    uint256 public investorCount;
    address public owner;
    uint256 public feePercent = 12;
    
    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    
    modifier onlyInvestor() {
        require(userDeposits[msg.sender] > 0, "Address not found");
        _;
    }
    
    modifier canWithdraw() {
        require(now >= userDepositTime[msg.sender].add(1 hours), "Too fast withdrawal request");
        _;
    }
    
    function withdraw() onlyInvestor canWithdraw internal {
        if (userDeposits[msg.sender].mul(2) <= userTotalWithdrawn[msg.sender]) {
            userDeposits[msg.sender] = 0;
            userDepositTime[msg.sender] = 0;
            userDailyWithdrawn[msg.sender] = 0;
        } else {
            uint256 payout = calculatePayout();
            userDailyWithdrawn[msg.sender] = userDailyWithdrawn[msg.sender].add(payout);
            userTotalWithdrawn[msg.sender] = userTotalWithdrawn[msg.sender].add(payout);
            msg.sender.transfer(payout);
            emit Withdraw(msg.sender, payout);
        }
    }
    
    function getDailyPercent() public view returns(uint256) {
        uint256 contractBalance = address(this).balance;
        if (contractBalance >= 0 ether) {
            return 24;
        }
    }
    
    function calculatePayout() public view returns(uint256) {
        uint256 dailyPercent = getDailyPercent();
        uint256 timePassed = now.sub(userDepositTime[msg.sender]).div(1 hours);
        uint256 dailyPayout = userDeposits[msg.sender].mul(dailyPercent).div(1000);
        uint256 totalPayout = dailyPayout.mul(timePassed).div(24).sub(userDailyWithdrawn[msg.sender]);
        return totalPayout;
    }
    
    function processInvestment() private {
        if (msg.value > 0) {
            if (userDeposits[msg.sender] == 0) {
                investorCount += 1;
            }
            
            if (userDeposits[msg.sender] > 0 && now > userDepositTime[msg.sender].add(1 hours)) {
                withdraw();
                userDailyWithdrawn[msg.sender] = 0;
            }
            
            userDeposits[msg.sender] = userDeposits[msg.sender].add(msg.value);
            userDepositTime[msg.sender] = now;
            
            owner.transfer(msg.value.mul(feePercent).div(100));
            emit Invest(msg.sender, msg.value);
            
            withdraw();
        }
    }
    
    function() external payable {
        processInvestment();
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