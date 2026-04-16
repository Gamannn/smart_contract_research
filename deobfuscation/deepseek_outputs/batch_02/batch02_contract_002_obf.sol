```solidity
pragma solidity ^0.4.20;

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
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract ERC20Basic {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    function ERC20Basic(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);
        
        uint256 previousBalances = balances[_from] + balances[_to];
        balances[_from] -= _value;
        balances[_to] += _value;
        
        Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
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
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}

contract AdvancedToken is Ownable, ERC20Basic {
    uint256 public sellPrice;
    mapping(address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);
    
    function AdvancedToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) ERC20Basic(initialSupply, tokenName, tokenSymbol) public {
        sellPrice = 2;
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        address _to = target;
        _to.transfer(mintedAmount);
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    function setPrices(uint256 newSellPrice) onlyOwner public {
        sellPrice = newSellPrice;
    }
    
    function sell(uint256 amount) public returns (uint256 revenue) {
        if(frozenAccount[msg.sender]) {
            revert();
        }
        
        require(balances[msg.sender] >= amount);
        balances[this] += amount;
        balances[msg.sender] -= amount;
        
        revenue = amount * (sellPrice / 10000);
        msg.sender.transfer(revenue);
        Transfer(msg.sender, this, amount);
        return revenue;
    }
    
    function buy(address _to, uint256 amount) onlyOwner public returns(uint256 balance) {
        require(balances[this] >= amount);
        balances[this] -= amount;
        balances[_to] += amount;
        Transfer(this, msg.sender, amount);
        balance = balances[this];
        return balance;
    }
    
    function() public payable {
    }
}
```