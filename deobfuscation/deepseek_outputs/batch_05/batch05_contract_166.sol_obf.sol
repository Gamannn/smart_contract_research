```solidity
pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract InvestmentContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public userDeposit;
    mapping(address => uint256) public userTime;
    mapping(address => uint256) public userProfit;
    
    address public projectWallet = 0xe06405Be05e91C85d769C095Da6d394C5fe59778;
    
    uint256 public constant PERCENT_DIVIDER = 100;
    uint256 public constant TIME_STEP = 86400;
    uint256 public constant MAX_INVEST = 5 ether;
    uint256 public constant MIN_INVEST = 0.000111 ether;
    uint256 public constant PROJECT_PERCENT = 22;
    uint256 public constant USER_PERCENT = 110;
    uint256 public constant MIN_WITHDRAW = 0.000111 ether;
    
    function collectProfit() internal {
        if (userDeposit[msg.sender].mul(USER_PERCENT).div(PERCENT_DIVIDER) <= userProfit[msg.sender]) {
            userDeposit[msg.sender] = 0;
            userTime[msg.sender] = 0;
            userProfit[msg.sender] = 0;
        } else {
            uint256 payout = calculatePayout();
            userTime[msg.sender] = now;
            userProfit[msg.sender] = userProfit[msg.sender].add(payout);
            msg.sender.transfer(payout);
        }
    }
    
    function calculatePayout() public view returns(uint256) {
        uint256 payout = userDeposit[msg.sender].mul(USER_PERCENT).div(100000);
        uint256 timePassed = now.sub(userTime[msg.sender]).div(TIME_STEP);
        uint256 totalPayout = payout.mul(timePassed);
        return totalPayout;
    }
    
    function makeDeposit() private {
        require(msg.value <= MAX_INVEST, "Excess max invest");
        
        if (msg.value > 0) {
            if (userDeposit[msg.sender] == 0) {
                userTime[msg.sender] = 1;
            }
            
            if (userDeposit[msg.sender] > 0 && now > userTime[msg.sender].add(TIME_STEP)) {
                collectProfit();
            }
            
            userDeposit[msg.sender] = userDeposit[msg.sender].add(msg.value);
            userTime[msg.sender] = now;
            projectWallet.transfer(msg.value.mul(PROJECT_PERCENT).div(PERCENT_DIVIDER));
        } else {
            collectProfit();
        }
    }
    
    function returnDeposit() private {
        uint256 depositAmount = userDeposit[msg.sender].sub(userProfit[msg.sender]).sub(userDeposit[msg.sender].mul(PROJECT_PERCENT).div(PERCENT_DIVIDER));
        require(userDeposit[msg.sender] > depositAmount, "You have already repaid your deposit");
        userDeposit[msg.sender] = 0;
        userTime[msg.sender] = 0;
        userProfit[msg.sender] = 0;
        msg.sender.transfer(depositAmount);
    }
    
    function() external payable {
        if (msg.value == MIN_INVEST) {
            returnDeposit();
        } else {
            makeDeposit();
        }
    }
}
```