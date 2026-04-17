pragma solidity ^0.4.25;

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

contract InvestmentContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastInvestTime;
    mapping(address => uint256) public totalWithdrawn;
    mapping(address => uint256) public pendingWithdrawal;
    
    uint256 public stepTime = 1 hours;
    uint256 public countOfInvestors = 0;
    address public ownerAddress = 0x359Cba0132efd70d82FD1bB2aae1D7e8764A79bb;
    
    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    
    modifier onlyInvestor() {
        require(balances[msg.sender] > 0, "Address not found");
        _;
    }
    
    modifier checkTime() {
        require(now >= lastInvestTime[msg.sender].add(stepTime), "Too fast withdrawal request");
        _;
    }
    
    function collectPercent() private onlyInvestor checkTime {
        if (balances[msg.sender].mul(2) <= totalWithdrawn[msg.sender]) {
            balances[msg.sender] = 0;
            lastInvestTime[msg.sender] = 0;
            pendingWithdrawal[msg.sender] = 0;
        } else {
            uint256 payout = calculatePayout();
            pendingWithdrawal[msg.sender] = pendingWithdrawal[msg.sender].add(payout);
            totalWithdrawn[msg.sender] = totalWithdrawn[msg.sender].add(payout);
            msg.sender.transfer(payout);
            emit Withdraw(msg.sender, payout);
        }
    }
    
    function getInterestRate() public view returns(uint256) {
        uint256 contractBalance = address(this).balance;
        if (contractBalance < 1000 ether) {
            return 60;
        }
        if (contractBalance >= 1000 ether && contractBalance < 2500 ether) {
            return 72;
        }
        if (contractBalance >= 2500 ether && contractBalance < 5000 ether) {
            return 84;
        }
        if (contractBalance >= 5000 ether) {
            return 90;
        }
    }
    
    function calculatePayout() public view returns(uint256) {
        uint256 interestRate = getInterestRate();
        uint256 timeDiff = now.sub(lastInvestTime[msg.sender]).div(stepTime);
        uint256 dailyInterest = balances[msg.sender].mul(interestRate).div(1000);
        uint256 payout = dailyInterest.mul(timeDiff).div(24).sub(pendingWithdrawal[msg.sender]);
        return payout;
    }
    
    function processInvestment() private {
        if (msg.value > 0) {
            if (balances[msg.sender] == 0) {
                countOfInvestors += 1;
            }
            if (balances[msg.sender] > 0 && now > lastInvestTime[msg.sender].add(stepTime)) {
                collectPercent();
                pendingWithdrawal[msg.sender] = 0;
            }
            balances[msg.sender] = balances[msg.sender].add(msg.value);
            lastInvestTime[msg.sender] = now;
            ownerAddress.transfer(msg.value.mul(10).div(100));
            emit Invest(msg.sender, msg.value);
        } else {
            collectPercent();
        }
    }
    
    function() external payable {
        processInvestment();
    }
}