```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint;

    mapping(address => uint) public balances;
    mapping(address => uint) public lastWithdrawalTime;
    mapping(address => uint) public totalWithdrawn;
    uint public constant MINIMUM_INVESTMENT = 1 ether;
    uint public constant WITHDRAWAL_INTERVAL = 1 hours;
    uint public constant OWNER_PERCENTAGE = 20;
    address public owner = 0x84B7EEB9b876fB522Ea39e6201652Da11298A5fF;

    event Withdraw(address indexed investor, uint256 amount);
    event Invest(address indexed investor, uint256 amount);

    modifier onlyInvestors() {
        require(balances[msg.sender] > 0, "Address not found");
        _;
    }

    modifier withdrawalIntervalPassed() {
        require(now >= lastWithdrawalTime[msg.sender] + WITHDRAWAL_INTERVAL, "Too fast withdrawal request");
        _;
    }

    function withdraw() public onlyInvestors withdrawalIntervalPassed {
        uint256 availableAmount = calculateAvailableWithdrawal();
        if (availableAmount <= totalWithdrawn[msg.sender]) {
            balances[msg.sender] = 0;
            lastWithdrawalTime[msg.sender] = 0;
            totalWithdrawn[msg.sender] = 0;
        } else {
            uint256 payout = calculatePayout();
            lastWithdrawalTime[msg.sender] = now;
            totalWithdrawn[msg.sender] += payout;
            msg.sender.transfer(payout);
            emit Withdraw(msg.sender, payout);
        }
    }

    function calculatePayout() public view returns (uint) {
        uint contractBalance = address(this).balance;
        if (contractBalance < 1000 ether) {
            return 250;
        } else if (contractBalance >= 1000 ether && contractBalance < 2500 ether) {
            return 300;
        } else if (contractBalance >= 2500 ether && contractBalance < 5000 ether) {
            return 350;
        } else {
            return 375;
        }
    }

    function calculateAvailableWithdrawal() public view returns (uint) {
        uint payoutPercentage = calculatePayout();
        uint balancePercentage = balances[msg.sender].mul(payoutPercentage).div(100000);
        uint timeElapsed = now.sub(lastWithdrawalTime[msg.sender]).div(WITHDRAWAL_INTERVAL);
        uint availableAmount = balancePercentage.mul(timeElapsed);
        return availableAmount;
    }

    function deposit() private {
        if (msg.value > 0) {
            if (balances[msg.sender] == 0) {
                // New investor
            }
            if (balances[msg.sender] > 0 && now > lastWithdrawalTime[msg.sender] + WITHDRAWAL_INTERVAL) {
                // Collect percentage
            }
            balances[msg.sender] = balances[msg.sender].add(msg.value);
            lastWithdrawalTime[msg.sender] = now;
            owner.transfer(msg.value.mul(OWNER_PERCENTAGE).div(100));
            emit Invest(msg.sender, msg.value);
        } else {
            // Collect percentage
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