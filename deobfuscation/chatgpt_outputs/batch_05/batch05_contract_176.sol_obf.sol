```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint;

    mapping(address => uint) public investments;
    mapping(address => uint) public lastInvestmentTime;
    mapping(address => uint) public withdrawnAmount;
    mapping(address => uint) public maxWithdrawAmount;

    uint public step;
    uint public investorCount;
    address public owner;

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);

    modifier hasInvestment() {
        require(investments[msg.sender] > 0, "Address not found");
        _;
    }

    modifier canWithdraw() {
        require(now >= lastInvestmentTime[msg.sender].add(step), "Too fast request");
        _;
    }

    function withdraw() internal hasInvestment canWithdraw {
        if (investments[msg.sender].mul(2) <= maxWithdrawAmount[msg.sender]) {
            investments[msg.sender] = 0;
            lastInvestmentTime[msg.sender] = 0;
            withdrawnAmount[msg.sender] = 0;
        } else {
            uint amountToWithdraw = calculateWithdrawAmount();
            withdrawnAmount[msg.sender] = withdrawnAmount[msg.sender].add(amountToWithdraw);
            maxWithdrawAmount[msg.sender] = maxWithdrawAmount[msg.sender].add(amountToWithdraw);
            msg.sender.transfer(amountToWithdraw);
            emit Withdraw(msg.sender, amountToWithdraw);
        }
    }

    function getStep() public view returns(uint) {
        uint stepValue = address(this).balance;
        if (stepValue >= 0 ether) {
            return 24;
        }
    }

    function calculateWithdrawAmount() public view returns(uint256) {
        uint256 stepValue = getStep();
        uint256 timePassed = now.sub(lastInvestmentTime[msg.sender]).div(step);
        uint256 maxAmount = investments[msg.sender].mul(stepValue).div(1000);
        uint256 withdrawAmount = maxAmount.mul(timePassed).div(24).sub(withdrawnAmount[msg.sender]);
        return withdrawAmount;
    }

    function invest() private {
        if (msg.value > 0) {
            if (investments[msg.sender] == 0) {
                investorCount += 1;
            }
            if (investments[msg.sender] > lastInvestmentTime[msg.sender].add(step)) {
                withdraw();
                maxWithdrawAmount[msg.sender] = 0;
            }
            investments[msg.sender] = investments[msg.sender].add(msg.value);
            lastInvestmentTime[msg.sender] = now;
            owner.transfer(msg.value.mul(step).div(100));
            emit Invest(msg.sender, msg.value);
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
```