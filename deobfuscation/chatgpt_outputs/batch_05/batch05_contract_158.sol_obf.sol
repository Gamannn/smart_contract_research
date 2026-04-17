pragma solidity ^0.4.25;

contract InvestmentContract {
    using SafeMath for uint;

    mapping(address => uint) public balances;
    mapping(address => uint) public lastInvestmentTime;
    mapping(address => uint) public withdrawnAmount;
    mapping(address => uint) public maxWithdrawAmount;

    uint public totalInvestors = 0;
    address public owner = 0x359Cba0132efd70d82FD1bB2aae1D7e8764A79bb;

    event Withdraw(address indexed investor, uint256 amount);
    event Invest(address indexed investor, uint256 amount);

    modifier onlyInvestor() {
        require(balances[msg.sender] > 0, "Address not found");
        _;
    }

    modifier canWithdraw() {
        require(now >= lastInvestmentTime[msg.sender] + 1 days, "Too fast withdrawal request");
        _;
    }

    function withdraw() public onlyInvestor canWithdraw {
        if (balances[msg.sender].mul(2) <= maxWithdrawAmount[msg.sender]) {
            balances[msg.sender] = 0;
            lastInvestmentTime[msg.sender] = 0;
            withdrawnAmount[msg.sender] = 0;
        } else {
            uint withdrawalAmount = calculateWithdrawAmount();
            withdrawnAmount[msg.sender] = withdrawnAmount[msg.sender].add(withdrawalAmount);
            maxWithdrawAmount[msg.sender] = maxWithdrawAmount[msg.sender].sub(withdrawalAmount);
            msg.sender.transfer(withdrawalAmount);
            emit Withdraw(msg.sender, withdrawalAmount);
        }
    }

    function getInterestRate() public view returns (uint) {
        uint contractBalance = address(this).balance;
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

    function calculateWithdrawAmount() public view returns (uint256) {
        uint256 interestRate = getInterestRate();
        uint256 timeElapsed = now.sub(lastInvestmentTime[msg.sender]).div(1 days);
        uint256 interest = balances[msg.sender].mul(interestRate).div(1000).mul(timeElapsed).div(24);
        return interest.sub(withdrawnAmount[msg.sender]);
    }

    function invest() private {
        if (msg.value > 0) {
            if (balances[msg.sender] == 0) {
                totalInvestors += 1;
            }
            if (balances[msg.sender] > 0 && now > lastInvestmentTime[msg.sender] + 1 days) {
                withdraw();
                withdrawnAmount[msg.sender] = 0;
            }
            balances[msg.sender] = balances[msg.sender].add(msg.value);
            lastInvestmentTime[msg.sender] = now;
            owner.transfer(msg.value.mul(10).div(100));
            emit Invest(msg.sender, msg.value);
        } else {
            withdraw();
        }
    }

    function() external payable {
        invest();
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