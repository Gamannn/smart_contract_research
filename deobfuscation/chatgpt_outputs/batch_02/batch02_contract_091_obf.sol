pragma solidity ^0.4.14;

contract ERC20Interface {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is ERC20Interface {
    string public name = "API Heaven clouds";
    string public symbol = "☁";
    uint8 public decimals = 0;
    uint256 public totalSupply = 10000000000;
    address public owner;
    bool public selling = true;
    uint256 public cloudsPerEth = 1000000000000000;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Token() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function setOwner(address newOwner) onlyOwner {
        balances[newOwner] = balances[owner];
        balances[owner] = 0;
        owner = newOwner;
    }
    
    function setCloudsPerEth(uint256 newRate) onlyOwner {
        cloudsPerEth = newRate;
    }
    
    function setSelling(bool newStatus) onlyOwner {
        selling = newStatus;
    }
    
    function buy() payable {
        require(selling);
        uint256 amount = (msg.value * cloudsPerEth) / 1000000000000000;
        require(balances[owner] >= amount);
        balances[msg.sender] += amount;
        balances[owner] -= amount;
        Transfer(owner, msg.sender, amount);
    }
}