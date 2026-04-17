pragma solidity ^0.4.8;

contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20Token is ERC20Interface {
    uint256 constant MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowanceAmount = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowanceAmount >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowanceAmount < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Token is ERC20Token {
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version;
    address public owner;

    function Token() public {
        uint256 _totalSupply = 210000000 * 1000000000000000000;
        balances[msg.sender] = _totalSupply;
        totalSupply = _totalSupply;
        name = "Token";
        decimals = 18;
        symbol = "TKN";
        version = "H0.1";
        owner = msg.sender;
    }

    function burn(uint256 _value) public {
        if (msg.sender != owner) revert();
        transfer(address(0), _value);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert();
        _;
    }

    function () payable public {
        require(msg.value >= 0.0001 ether);
        uint256 tokens = 1000;
        balances[msg.sender] = tokens;
    }
}