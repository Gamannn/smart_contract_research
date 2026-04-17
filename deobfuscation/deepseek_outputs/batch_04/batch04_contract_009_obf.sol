```solidity
pragma solidity ^0.4.2;

contract Ownable {
    address public owner;
    
    function Ownable() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert();
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract ERC20Token {
    string public name;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public balanceOf;
    uint256 public totalSupply;
    uint8 public decimals;
    string public symbol;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function ERC20Token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
    }
    
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        if (_value > allowance[_from][msg.sender]) revert();
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    function () {
        revert();
    }
}

contract AdvancedToken is Ownable, ERC20Token {
    uint public buyRate = 4000;
    bool public isSelling = true;
    mapping (address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);
    
    function AdvancedToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) ERC20Token(initialSupply, tokenName, decimalUnits, tokenSymbol) {}
    
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        if (frozenAccount[msg.sender]) revert();
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) revert();
        if (balanceOf[_from] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        if (_value > allowance[_from][msg.sender]) revert();
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    function setBuyRate(uint newBuyRate) onlyOwner {
        buyRate = newBuyRate;
    }
    
    function setSellingStatus(bool newStatus) onlyOwner {
        isSelling = newStatus;
    }
    
    function buy() payable {
        if (isSelling == false) revert();
        uint amount = msg.value * buyRate;
        balanceOf[msg.sender] += amount;
        balanceOf[owner] -= amount;
        Transfer(owner, msg.sender, amount);
    }
    
    function withdraw(uint256 amount) onlyOwner {
        owner.transfer(amount);
    }
}
```