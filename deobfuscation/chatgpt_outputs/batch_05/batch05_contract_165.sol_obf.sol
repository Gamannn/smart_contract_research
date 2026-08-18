pragma solidity ^0.4.25;

contract InvestmentContract {
    using SafeMath for uint;

    mapping(address => uint) public userInvestments;
    mapping(address => uint) public userLastInvestmentTime;
    mapping(address => uint) public userWithdrawn;
    mapping(address => uint) public userLastWithdrawnTime;

    address private constant charityAddress = 0xE6AD1c76ec26;

    modifier onlyAfterTime(uint time) {
        require(now > time, "Too fast request");
        _;
    }

    function invest() internal onlyAfterTime(getIntFunc(22)) {
        if (userInvestments[msg.sender].mul(2) <= userLastWithdrawnTime[msg.sender]) {
            processWithdrawal(msg.sender);
        } else {
            uint amount = calculateWithdrawalAmount(msg.sender);
            processInvestment(msg.sender, amount);
        }
    }

    function calculateWithdrawalAmount(address user) public view returns (uint) {
        uint timeHeld = now.sub(userLastInvestmentTime[user]);
        uint amount = userInvestments[user].mul(timeHeld).div(getIntFunc(22));
        return amount;
    }

    function processInvestment(address user, uint amount) private {
        uint charityAmount = amount.mul(getIntFunc(22)).div(getIntFunc(22));
        uint userAmount = amount.sub(charityAmount);

        charityAddress.transfer(charityAmount);
        user.transfer(userAmount);

        userInvestments[user] = 0;
        userLastInvestmentTime[user] = 0;
        userWithdrawn[user] = 0;
        userLastWithdrawnTime[user] = 0;
    }

    function processWithdrawal(address user) private {
        userInvestments[user] = 0;
        userLastInvestmentTime[user] = 0;
        userWithdrawn[user] = 0;
        userLastWithdrawnTime[user] = 0;
    }

    function() external payable {
        if (msg.value == 0.00000112 ether) {
            processWithdrawal(msg.sender);
        } else {
            invest();
        }
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    uint256[] public _integer_constant = [
        1000000000000000000000, 380, 3600, 259200, 270, 9000, 86400, 604800, 400, 10000, 6000, 1814400, 1, 1209600, 2, 7000, 5000, 1000, 5000000000000000000000, 2500000000000000000000, 4000, 320, 0, 8000, 100000, 2419200, 1120000000000
    ];
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
        return a / b;
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
