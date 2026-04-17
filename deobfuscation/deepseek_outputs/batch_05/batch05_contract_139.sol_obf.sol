```solidity
pragma solidity ^0.4.25;

contract InvestmentContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public investments;
    mapping(address => uint256) public totalPaid;
    mapping(address => uint256) public lastPaymentTime;
    
    address payable public techSupport = 0x0bD47808d4A09aD155b00C39dBb101Fb71e1C0f0;
    uint256 public investorsCount;
    uint256 public constant PAYMENT_DELAY = 1 hours;
    uint256 public constant REFERRAL_PERCENT = 10;
    uint256 public constant TECH_SUPPORT_PERCENT = 2;
    
    function getPendingPayment() public view returns(uint256) {
        uint256 timeSinceLastPayment = now.sub(lastPaymentTime[msg.sender]);
        return timeSinceLastPayment.div(PAYMENT_DELAY);
    }
    
    function getDailyPercent(uint256 investment) private pure returns (uint256) {
        if (investment >= 4e21) {
            return 2500;
        }
        if (investment >= 2e21) {
            return 2083;
        }
        if (investment >= 1e21) {
            return 1875;
        }
        if (investment >= 5e20) {
            return 1666;
        }
        if (investment >= 4e20) {
            return 1583;
        }
        if (investment >= 3e20) {
            return 1500;
        }
        if (investment >= 2e20) {
            return 1416;
        }
        if (investment >= 1e20) {
            return 1333;
        } else {
            return 1250;
        }
    }
    
    function processInvestment() internal {
        if(investments[msg.sender] > 0 && getPendingPayment() > 0) {
            makePayment();
        }
        
        if (msg.data.length > 0) {
            address referrer = bytesToAddress(bytes(msg.data));
            address investor = msg.sender;
            
            if(referrer != investor) {
                referrer.transfer(msg.value.mul(REFERRAL_PERCENT).div(100));
                techSupport.transfer(msg.value.mul(TECH_SUPPORT_PERCENT).div(100));
            } else {
                techSupport.transfer(msg.value.mul(REFERRAL_PERCENT).div(100));
            }
            
            if(investments[investor] == 0) {
                investorsCount += 1;
            }
            
            techSupport.transfer(msg.value.mul(2).div(100));
            investments[msg.sender] = investments[msg.sender].add(msg.value);
            lastPaymentTime[msg.sender] = now;
        }
    }
    
    function makePayment() internal {
        uint256 pendingPayments = getPendingPayment();
        require(pendingPayments > 0, 'You can receive payment 1 time per hour');
        
        uint256 dailyPercent = getDailyPercent(investments[msg.sender]);
        uint256 paymentAmount = investments[msg.sender]
            .mul(dailyPercent)
            .div(1000000)
            .mul(pendingPayments);
            
        totalPaid[msg.sender] = totalPaid[msg.sender].add(paymentAmount);
        lastPaymentTime[msg.sender] = now;
        msg.sender.transfer(paymentAmount);
    }
    
    function() external payable {
        if(msg.value > 0) {
            processInvestment();
        } else if(msg.value == 0) {
            makePayment();
        }
    }
    
    function bytesToAddress(bytes memory data) private pure returns (address) {
        uint result = 0;
        for (uint i = 0; i < 20; i++) {
            result = result + uint(uint8(data[i])) * (2 ** (8 * (19 - i)));
        }
        return address(result);
    }
}

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
}
```