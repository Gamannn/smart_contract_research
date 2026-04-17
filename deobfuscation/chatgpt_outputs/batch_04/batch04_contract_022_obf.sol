```solidity
pragma solidity ^0.4.18;

contract Token {
    function transfer(address to, uint256 value) public returns (bool success);
}

contract ExternalContract {
    function someFunction(address) public payable returns (uint256);
    function transfer(address, uint256) public returns (bool);
    function getTokenBalance() public view returns (uint256);
    function getSomeValue(bool) public view returns (uint256);
    function executeAction() public;
}

contract BaseContract {
    ExternalContract public externalContract;

    function BaseContract(address contractAddress) public {
        externalContract = ExternalContract(contractAddress);
    }

    modifier onlyExternalContract() {
        require(msg.sender == address(externalContract));
        _;
    }

    function executeTransaction(address to, uint256 value, bytes data) external returns (bool);
}

contract MainContract is BaseContract {
    uint256 public constant DAY_IN_SECONDS = 86400;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastTransactionTime;
    mapping(address => uint256) public someMapping;
    uint256 public someValue;

    function MainContract(address contractAddress) BaseContract(contractAddress) public {
        owner = msg.sender;
    }

    function() payable public {}

    function executeTransaction(address to, uint256 value, bytes data) external onlyExternalContract returns (bool) {
        require(initialized);
        require(!isContract(to));
        require(value >= 1 finney);

        uint256 tokenBalance = externalContract.getTokenBalance();
        uint256 calculatedValue = calculateValue(value, tokenBalance);
        calculatedValue = adjustValue(calculatedValue, calculateAdjustment(calculatedValue));

        executeAction();
        externalContract.transfer(owner, calculateAdjustment(value));
        balances[to] = add(balances[to], calculatedValue);

        return true;
    }

    function setMappingValue(address addr) public {
        require(initialized);
        require(someMapping[msg.sender] == 0 && someMapping[msg.sender] != msg.sender);
        someMapping[msg.sender] = addr;
    }

    function calculateValue(uint256 value, uint256 tokenBalance) public view returns (uint256) {
        return calculate(value, tokenBalance, someValue);
    }

    function calculateAdjustment(uint256 value) public view returns (uint256) {
        return calculate(value, externalContract.getTokenBalance(), someValue);
    }

    function adjustValue(uint256 value, uint256 adjustment) public view returns (uint256) {
        return SafeMath.div(SafeMath.mul(value, adjustment), 100);
    }

    function executeAction() public {
        if (externalContract.getSomeValue(true) > 1) {
            externalContract.executeAction();
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function calculate(uint256 a, uint256 b, uint256 c) private pure returns (uint256) {
        return a < b ? a : b;
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

function getBoolFunc(uint256 index) internal view returns (bool) {
    return _bool_constant[index];
}

function getIntFunc(uint256 index) internal view returns (uint256) {
    return _integer_constant[index];
}

bool[] public _bool_constant = [true, false];
uint256[] public _integer_constant = [5000, 10000, 100, 1000000000000000, 300, 86400, 4, 5, 1, 10, 0];
```