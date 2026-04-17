pragma solidity ^0.4.13;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract ERC20 {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address who) constant returns (uint256 balance) {}
    function transfer(address to, uint256 value) returns (bool success) {}
    function transferFrom(address from, address to, uint256 value) returns (bool success) {}
    function approve(address spender, uint256 value) returns (bool success) {}
    function allowance(address owner, address spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20 {
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

    function balanceOf(address who) constant returns (uint256 balance) {
        return balances[who];
    }

    function approve(address spender, uint256 value) returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 public totalSupply;
}

contract EventToken is StandardToken, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    address public creator;

    function EventToken(string _name, string _symbol) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        creator = msg.sender;
    }

    function mint(address to, uint amount) {
        require(msg.sender == creator);
        balances[to] = safeAdd(balances[to], amount);
        totalSupply = safeAdd(totalSupply, amount);
    }

    function burn(address from, uint amount) {
        require(msg.sender == creator);
        require(balances[from] >= amount);
        balances[from] = safeSub(balances[from], amount);
        totalSupply = safeSub(totalSupply, amount);
    }
}

contract PredictionMarket {
    EventToken public yesToken;
    EventToken public noToken;
    string public name;
    string public symbol;
    string public description;
    uint public fee;
    bool public resolved;
    address public feeAccount;
    address public oracle;
    bytes32 public oracleMessageHash;
    uint public outcome;
    address public creator;
    uint public creationTime;

    event Create(address indexed participant, uint amount);
    event Redeem(address indexed participant, uint amount, uint yesAmount, uint noAmount);
    event Resolve(bool outcome, uint result);

    function PredictionMarket(
        string _name,
        string _symbol,
        string _yesName,
        string _yesSymbol,
        string _noName,
        string _noSymbol,
        bytes32 _oracleMessageHash,
        address _oracle,
        string _description,
        address _feeAccount,
        uint _fee
    ) {
        name = _name;
        symbol = _symbol;
        yesToken = new EventToken(_yesName, _yesSymbol);
        noToken = new EventToken(_noName, _noSymbol);
        oracleMessageHash = _oracleMessageHash;
        oracle = _oracle;
        description = _description;
        feeAccount = _feeAccount;
        fee = _fee;
        creator = msg.sender;
        creationTime = now;
    }

    function() payable {
        create();
    }

    function create() payable {
        yesToken.mint(msg.sender, msg.value);
        noToken.mint(msg.sender, msg.value);
        Create(msg.sender, msg.value);
    }

    function redeem(uint amount) {
        feeAccount.transfer(safeMul(amount, fee) / (1 ether));
        if (!resolved) {
            yesToken.burn(msg.sender, amount);
            noToken.burn(msg.sender, amount);
            msg.sender.transfer(safeMul(amount, (1 ether) - fee) / (1 ether));
            Redeem(msg.sender, amount, amount, amount);
        } else if (resolved) {
            if (outcome == 0) {
                noToken.burn(msg.sender, amount);
                msg.sender.transfer(safeMul(amount, (1 ether) - fee) / (1 ether));
                Redeem(msg.sender, amount, 0, amount);
            } else if (outcome == 1) {
                yesToken.burn(msg.sender, amount);
                msg.sender.transfer(safeMul(amount, (1 ether) - fee) / (1 ether));
                Redeem(msg.sender, amount, amount, 0);
            }
        }
    }

    function resolve(uint8 v, bytes32 r, bytes32 s, bytes32 resultHash) {
        require(ecrecover(sha3(oracleMessageHash), v, r, s) == oracle);
        resolved = true;
        outcome = uint(resultHash);
        require(outcome == 0 || outcome == 1);
        Resolve(resolved, outcome);
    }
}