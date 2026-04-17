```solidity
pragma solidity ^0.4.4;

contract TokenInterface {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is TokenInterface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract JPMorganChaseToken is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    address public fundsWallet;
    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;

    function JPMorganChaseToken() {
        balances[msg.sender] = 6000000;
        totalSupply = 6000000;
        name = "JPMorgan Chase";
        decimals = 0;
        symbol = "JPMC";
        unitsOneEthCanBuy = 99000;
        fundsWallet = msg.sender;
    }

    function() payable {
        totalEthInWei += msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (balances[fundsWallet] >= amount) {
            balances[fundsWallet] -= amount;
            balances[msg.sender] += amount;
            Transfer(fundsWallet, msg.sender, amount);
            fundsWallet.transfer(msg.value);
        }
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if (!_spender.call(bytes4(keccak256("receiveApproval(address,uint256,address,bytes)")), msg.sender, _value, this, _extraData)) {
            throw;
        }
        return true;
    }
}
```