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

    function withdraw() onlyOwner public {
        owner.transfer(this.balance);
    }

    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract Token {
    string public name = "BOSS";
    string public symbol = "BOSS";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function Token(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
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
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
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
}

contract AdvancedToken is Ownable, Token {
    uint public minBalanceForAccounts = 2 * 1 finney;
    uint public commissionPercentage = 2;
    uint256 public buyPrice = 7653;
    uint256 public sellPrice = 7653;
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function _transfer(address _from, address _to, uint _value) internal {
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] -= _value;
        balanceOf[owner] += _value * commissionPercentage / 100;
        balanceOf[_to] += _value - (_value * commissionPercentage / 100);
        if (_to.balance < minBalanceForAccounts) {
            _to.transfer((minBalanceForAccounts - _to.balance) * buyPrice);
        }
        Transfer(_from, owner, _value * commissionPercentage / 100);
        Transfer(_from, _to, _value - (_value * commissionPercentage / 100));
    }

    function setMinBalance(uint minimumBalanceInFinney) onlyOwner public {
        minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }

    function setCommissionPercentage(uint commissionPercent) onlyOwner public {
        commissionPercentage = commissionPercent;
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

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function () payable public {
        buy();
    }

    function buy() payable public {
        uint amount = msg.value * buyPrice;
        _transfer(this, msg.sender, amount);
    }

    function sell(uint256 amount) public {
        require(this.balance >= amount / sellPrice);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount / sellPrice);
    }
}
```