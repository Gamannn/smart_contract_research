```solidity
pragma solidity ^0.4.8;

contract TokenInterface {
    function totalSupply() constant returns (uint);
    function balanceOf(address owner) constant returns (uint256);
    function allowance(address owner, address spender) constant returns (uint);
    function transfer(address to, uint value) returns (bool success);
    function approve(address spender, uint value) returns (bool success);
    function transferFrom(address from, address to, uint value) returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BOPToken is TokenInterface {
    string public name = "BlockOp";
    string public symbol = "BOP";
    uint8 public decimals = 18;
    uint public totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function BOPToken() {
        owner = msg.sender;
        totalSupply = 1000000 * 10 ** uint(decimals);
        balances[owner] = totalSupply;
    }

    function totalSupply() constant returns (uint) {
        return totalSupply;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint _value) returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function mint(uint _amount) onlyOwner {
        totalSupply += _amount;
        balances[owner] += _amount;
        Transfer(0x0, owner, _amount);
    }

    function burn(uint _amount) onlyOwner {
        require(balances[owner] >= _amount);
        totalSupply -= _amount;
        balances[owner] -= _amount;
        Transfer(owner, 0x0, _amount);
    }
}
```