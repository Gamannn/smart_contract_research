```solidity
pragma solidity ^0.4.16;

contract owned {
    address public owner;
    
    function owned() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 15;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowanceBurn;
    mapping(address => mapping(address => uint256)) public allowanceTransfer;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowanceTransfer[_from][msg.sender]);
        allowanceTransfer[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approveTransfer(address _spender, uint256 _value) public returns (bool success) {
        allowanceTransfer[msg.sender][_spender] = _value;
        return true;
    }
    
    function approveBurn(address _spender, uint256 _value) public returns (bool success) {
        allowanceBurn[msg.sender][_spender] = _value;
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowanceBurn[_from][msg.sender]);
        
        balanceOf[_from] -= _value;
        allowanceBurn[_from][msg.sender] -= _value;
        totalSupply -= _value;
        
        Burn(_from, _value);
        return true;
    }
}

contract RESToken is owned, TokenERC20 {
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public initialSupply = 8551000000;
    uint256 public initialBuyPrice = 1000;
    uint256 public initialSellPrice = 1000;
    
    string tokenName = "Resource";
    string tokenSymbol = "RES";
    
    function RESToken() TokenERC20(initialSupply, tokenName, tokenSymbol) public {
        sellPrice = initialSellPrice;
        buyPrice = initialBuyPrice;
        
        allowanceBurn[this][msg.sender] = initialSupply / 2 * (10 ** uint256(decimals));
    }
    
    function updatePrice() public {
        sellPrice = initialSellPrice * initialSupply / totalSupply;
        buyPrice = initialBuyPrice * initialSupply / totalSupply;
    }
    
    function buy() payable public {
        uint256 amount = msg.value * 1000 / buyPrice;
        _transfer(this, msg.sender, amount);
    }
    
    function sell(uint256 amount) public {
        require(address(this).balance >= amount * sellPrice / 1000);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount * sellPrice / 1000);
    }
}
```