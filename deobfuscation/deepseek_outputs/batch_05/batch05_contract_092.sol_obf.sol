```solidity
pragma solidity ^0.4.8;

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == b * c + a % b);
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        require(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        require(c >= a && c >= b);
        return c;
    }
    
    function require(bool condition) internal {
        if (!condition) {
            throw;
        }
    }
}

contract Token is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public freezeOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    
    function Token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        decimals = decimalUnits;
        symbol = tokenSymbol;
        owner = msg.sender;
    }
    
    function transfer(address to, uint256 value) {
        if (to == 0x0) throw;
        if (value <= 0) throw;
        if (balanceOf[msg.sender] < value) throw;
        if (balanceOf[to] + value < balanceOf[to]) throw;
        
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        Transfer(msg.sender, to, value);
    }
    
    function approve(address spender, uint256 value) returns (bool success) {
        if (value <= 0) throw;
        allowance[msg.sender][spender] = value;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        if (to == 0x0) throw;
        if (value <= 0) throw;
        if (balanceOf[from] < value) throw;
        if (balanceOf[to] + value < balanceOf[to]) throw;
        if (value > allowance[from][msg.sender]) throw;
        
        balanceOf[from] = safeSub(balanceOf[from], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], value);
        Transfer(from, to, value);
        return true;
    }
    
    function burn(uint256 value) returns (bool success) {
        if (balanceOf[msg.sender] < value) throw;
        if (value <= 0) throw;
        
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        Burn(msg.sender, value);
        return true;
    }
    
    function freeze(uint256 value) returns (bool success) {
        if (balanceOf[msg.sender] < value) throw;
        if (value <= 0) throw;
        
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        freezeOf[msg.sender] = safeAdd(freezeOf[msg.sender], value);
        Freeze(msg.sender, value);
        return true;
    }
    
    function unfreeze(uint256 value) returns (bool success) {
        if (freezeOf[msg.sender] < value) throw;
        if (value <= 0) throw;
        
        freezeOf[msg.sender] = safeSub(freezeOf[msg.sender], value);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], value);
        Unfreeze(msg.sender, value);
        return true;
    }
    
    function withdrawEther(uint256 amount) {
        if (msg.sender != owner) throw;
        owner.transfer(amount);
    }
    
    function() payable {
    }
}
```