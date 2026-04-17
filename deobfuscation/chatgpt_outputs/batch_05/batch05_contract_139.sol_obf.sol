```solidity
pragma solidity ^0.4.25;

contract InvestmentContract {
    using SafeMath for uint;

    mapping(address => uint) public investments;
    mapping(address => uint) public payouts;
    mapping(address => uint) public lastInvestmentTime;
    address techSupport;

    function getPaymentDelay() public view returns (uint) {
        return now.sub(lastInvestmentTime[msg.sender]).div(1 hours);
    }

    function getInterestRate(uint amount) private pure returns (uint) {
        if (amount >= 4e21) {
            return 2500;
        }
        if (amount >= 2e21) {
            return 2083;
        }
        if (amount >= 1e21) {
            return 1875;
        }
        if (amount >= 5e20) {
            return 1666;
        }
        if (amount >= 4e20) {
            return 1583;
        }
        if (amount >= 3e20) {
            return 1500;
        }
        if (amount >= 2e20) {
            return 1416;
        }
        if (amount >= 1e20) {
            return 1333;
        } else {
            return 1250;
        }
    }

    function processInvestment() internal {
        if (investments[msg.sender] > 0 && getPaymentDelay() > 0) {
            payout();
        }
        if (msg.data.length > 0) {
            address referrer = bytesToAddress(bytes(msg.data));
            address investor = msg.sender;
            if (referrer != investor) {
                referrer.transfer(msg.value.mul(5).div(100));
            }
        }
        if (investments[msg.sender] == 0) {
            investors += 1;
        }
        techSupport.transfer(msg.value.mul(10).div(100));
        investments[msg.sender] += msg.value;
        lastInvestmentTime[msg.sender] = now;
    }

    function payout() internal {
        uint payoutAmount = getPaymentDelay();
        require(payoutAmount > 0, "You can receive payment 1 time per hour");
        uint amount = address(this).balance.mul(getInterestRate(investments[msg.sender])).div(1000000).mul(payoutAmount);
        payouts[msg.sender] += amount;
        lastInvestmentTime[msg.sender] = now;
        msg.sender.transfer(amount);
    }

    function() external payable {
        if (msg.value > 0) {
            processInvestment();
        } else if (msg.value == 0) {
            payout();
        }
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
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