pragma solidity >=0.4.22 <0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract PrimeChecker {
    using SafeMath for uint256;

    mapping(uint => uint) private balances;

    function deposit(uint256 primeCandidate) public payable {
        balances[primeCandidate] = balances[primeCandidate].add(msg.value);
    }

    event NotPrime(uint primeCandidate);

    function checkAndWithdraw(uint primeCandidate1, uint primeCandidate2) public {
        require(primeCandidate1 > 1, "PrimeChecker: candidate must be greater than 1");
        require(primeCandidate2 > 1, "PrimeChecker: candidate must be greater than 1");

        uint product = SafeMath.mul(primeCandidate1, primeCandidate2);
        uint balance = balances[product];
        balances[product] = 0;
        msg.sender.transfer(balance);

        emit NotPrime(product);
    }

    function getBalance(uint primeCandidate) public view returns (uint) {
        return balances[primeCandidate];
    }
}

function getIntFunc(uint256 index) internal view returns (uint256) {
    return _integer_constant[index];
}

uint256[] public _integer_constant = [1, 0];