```solidity
pragma solidity ^0.4.13;

contract MathOperations {
    function safeMultiply(uint a, uint b) internal returns (uint) {
        uint result = a * b;
        assert(a == 0 || result / a == b);
        return result;
    }

    function safeSubtract(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint result = a + b;
        assert(result >= a && result >= b);
        return result;
    }
}

contract ERC20Interface {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance) {}
    function transfer(address to, uint256 value) returns (bool success) {}
    function transferFrom(address from, address to, uint256 value) returns (bool success) {}
    function approve(address spender, uint256 value) returns (bool success) {}
    function allowance(address owner, address spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20Interface, MathOperations {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 public totalSupply;

    function transfer(address to, uint256 value) returns (bool success) {
        if (balances[msg.sender] >= value && balances[to] + value > balances[to]) {
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && balances[to] + value > balances[to]) {
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }

    function approve(address spender, uint256 value) returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract Token is StandardToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;

    function Token(string tokenName, string tokenSymbol, uint8 decimalUnits) {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        owner = msg.sender;
    }

    function mint(address to, uint amount) {
        require(msg.sender == owner);
        balances[to] = safeAdd(balances[to], amount);
        totalSupply = safeAdd(totalSupply, amount);
    }

    function burn(address from, uint amount) {
        require(msg.sender == owner);
        require(balances[from] >= amount);
        balances[from] = safeSubtract(balances[from], amount);
        totalSupply = safeSubtract(totalSupply, amount);
    }
}

contract PredictionMarket {
    struct Market {
        uint256 fee;
        address feeAccount;
        bool resolved;
        uint256 outcome;
        string description;
        address oracle;
        string category;
        string subcategory;
        address creator;
        uint256 resolutionDate;
    }

    Market public market;
    bool[] public _bool_constant = [true, false];
    uint256[] public _integer_constant = [18, 1, 0, 1000000000000000000];

    function getBoolConstant(uint256 index) internal view returns(bool) {
        return _bool_constant[index];
    }

    function getIntConstant(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    event Resolve(bool resolved, uint outcome);

    function PredictionMarket(
        string description,
        string category,
        string subcategory,
        string oracleName,
        string oracleDescription,
        string oracleCategory,
        bytes32 oracleHash,
        address oracleAddress,
        string creatorName,
        address creatorAddress,
        uint resolutionDate
    ) {
        market.description = description;
        market.category = category;
        market.oracle = new Oracle(oracleName, oracleDescription);
        market.creator = creatorAddress;
        market.subcategory = subcategory;
        market.feeAccount = oracleAddress;
        market.resolutionDate = resolutionDate;
    }

    function resolveMarket(uint8 v, bytes32 r, bytes32 s, bytes32 hash) {
        require(ecrecover(sha3(market.oracle), v, r, s) == market.oracle);
        market.resolved = true;
        market.outcome = uint(hash);
        require(market.outcome == 0 || market.outcome == 1);
        Resolve(market.resolved, market.outcome);
    }
}

contract Oracle {
    string public name;
    string public description;

    function Oracle(string oracleName, string oracleDescription) {
        name = oracleName;
        description = oracleDescription;
    }
}
```