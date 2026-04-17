```solidity
pragma solidity ^0.4.16;

contract Ownable {
    address public owner;
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ERC20Base {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    function ERC20Base(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);
        
        uint previousBalances = balances[_from] + balances[_to];
        balances[_from] -= _value;
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balances[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
    
    mapping (address => uint256) public balances;
    uint256 public totalSupply;
}

contract ENTCToken is Ownable, ERC20Base {
    uint256 initialSupply = 1600000000;
    uint256 public buyPrice = 1;
    
    event FrozenFunds(address target, bool frozen);
    
    function ENTCToken() ERC20Base(initialSupply, "ENTChain", "ENTC") public {
    }
    
    function setPrices(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }
    
    function buy() payable public {
        uint amount = msg.value / buyPrice;
    }
    
    function () payable public {
        owner.send(msg.value);
        uint amount = msg.value * buyPrice;
        _transfer(owner, msg.sender, amount);
    }
    
    function kill() onlyOwner public {
        selfdestruct(owner);
    }
}
```