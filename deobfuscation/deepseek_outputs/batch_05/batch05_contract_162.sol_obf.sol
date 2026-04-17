```solidity
pragma solidity ^0.4.24;

contract Ownable {
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract Token is Ownable {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    bool public stopped;
    bool public mintingFinished;
    
    constructor() public {
        name = "Leimen coin";
        symbol = "Lem";
        decimals = 18;
        totalSupply = 1000000000 * 10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        mintingFinished = false;
    }
    
    function mint(uint256 mintedAmount) onlyOwner public {
        require(!mintingFinished);
        balanceOf[msg.sender] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, msg.sender, mintedAmount);
    }
    
    function setName(string _name) onlyOwner public {
        name = _name;
    }
    
    function setSymbol(string _symbol) onlyOwner public {
        symbol = _symbol;
    }
    
    function finishMinting() onlyOwner public {
        mintingFinished = true;
    }
    
    function start() onlyOwner public {
        stopped = false;
    }
    
    function stop() onlyOwner public {
        stopped = true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(!frozenAccount[_from]);
        require(!stopped);
        require(_to != address(0));
        require(_value >= 0);
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
    
    function () payable public {
        buy();
    }
    
    function buy() payable public returns (uint256 amount) {
        uint256 price = 100;
        require(price != 0);
        require(mintingFinished);
        amount = msg.value / price * 100;
        require(balanceOf[this] > amount);
        balanceOf[msg.sender] += amount;
        balanceOf[this] -= amount;
        Transfer(this, msg.sender, amount);
        return amount;
    }
}
```