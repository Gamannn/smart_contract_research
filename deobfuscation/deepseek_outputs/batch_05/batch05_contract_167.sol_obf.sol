```solidity
pragma solidity ^0.4.18;

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
    
    function withdrawTokens(address tokenAddress) onlyOwner public {
        ERC20 token = ERC20(tokenAddress);
        token.transfer(owner, token.balanceOf(this));
    }
    
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
}

contract ERC20 {
    function transfer(address to, uint256 value, address from, bytes data) public;
}

contract StandardToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    function StandardToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        symbol = tokenSymbol;
        name = tokenName;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
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
        ERC20 spender = ERC20(_spender);
        if (approve(_spender, _value)) {
            spender.transfer(msg.sender, _value, this, _extraData);
            return true;
        }
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
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
    
    uint256 public totalSupply;
}

contract BOSSToken is Ownable, StandardToken {
    uint minimumBalanceInFinney = 2 * 1 finney;
    uint commissionPercent = 2;
    uint256 public buyPrice = 7653;
    uint256 public sellPrice = 7653;
    mapping (address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);
    
    function BOSSToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) StandardToken(initialSupply, tokenName, tokenSymbol) public {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        
        balanceOf[_from] -= _value;
        balanceOf[owner] += _value * commissionPercent / 100;
        balanceOf[_to] += _value - (_value * commissionPercent / 100);
        
        if(_to.balance < minimumBalanceInFinney) {
            uint amountInBoss = (minimumBalanceInFinney - _to.balance) * buyPrice;
            _to.transfer(amountInBoss / buyPrice);
        }
        
        Transfer(_from, owner, _value * commissionPercent / 100);
        Transfer(_from, _to, _value - (_value * commissionPercent / 100));
    }
    
    function setMinimumBalance(uint minimumBalanceInFinney_) onlyOwner public {
        minimumBalanceInFinney = minimumBalanceInFinney_;
    }
    
    function setCommissionPercent(uint commissionPercent_) onlyOwner public {
        commissionPercent = commissionPercent_;
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    function setPrices(uint256 newBuyPrice, uint256 newSellPrice) onlyOwner public {
        buyPrice = newBuyPrice;
        sellPrice = newSellPrice;
    }
    
    function () payable public {
        buy();
    }
    
    function buy() payable public {
        uint amount = msg.value * buyPrice;
        _transfer(this, msg.sender, amount);
    }
    
    function sell(uint256 amount) public {
        require(this.balance >= amount / buyPrice);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount / buyPrice);
    }
}
```