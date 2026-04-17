pragma solidity ^0.4.24;

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

    address public owner;
    mapping(address => uint) public deposits;
    mapping(address => uint) public lastInvestmentTime;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address newOwner) external {
        require(msg.sender == owner);
        require(newOwner != address(0));
        owner = newOwner;
    }

    function getInvestorInfo() public view returns (uint deposit, uint lastInvestment, uint profit) {
        deposit = deposits[msg.sender];
        lastInvestment = lastInvestmentTime[msg.sender];
        profit = calculateProfit(msg.sender);
    }

    function() external payable {
        invest();
    }

    function invest() public payable {
        require(msg.value > 0.01 ether);
        owner.transfer(msg.value.div(5));

        if (deposits[msg.sender] > 0) {
            uint profit = calculateProfit(msg.sender);
            if (profit != 0) {
                deposits[msg.sender] = deposits[msg.sender].add(profit);
                msg.sender.transfer(profit);
            }
        }

        lastInvestmentTime[msg.sender] = block.timestamp;
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
    }

    function withdrawProfit() public {
        uint profit = calculateProfit(msg.sender);
        require(profit != 0);

        deposits[msg.sender] = deposits[msg.sender].add(profit);
        lastInvestmentTime[msg.sender] = block.timestamp;
        msg.sender.transfer(profit);
    }

    function calculateProfit(address investor) internal view returns (uint) {
        uint timePassed = block.timestamp.sub(lastInvestmentTime[investor]);
        uint dailyProfit = deposits[investor].mul(3).div(100);
        return dailyProfit.mul(timePassed).div(1 days);
    }
}