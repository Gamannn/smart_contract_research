```solidity
pragma solidity ^0.4.13;

contract Ownable {
    address public owner;
    
    function Ownable() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract ERC20Token is Ownable {
    string public name;
    string public symbol;
    bool public locked;
    uint8 public decimals;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event IcoFinished();
    
    uint256 public rate = 1;
    
    function transfer(address _to, uint256 _value) {
        require(locked == false);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
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
        require(locked == false);
        require(_value > 0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(_value <= allowance[_from][msg.sender]);
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    function buyTokens(uint256 _weiAmount, uint256 _timestamp) internal {
        require(locked == false);
        require(_timestamp >= icoStart && _timestamp <= icoEnd);
        require(_weiAmount > 0);
        
        uint256 tokens = _weiAmount / rate;
        require(balanceOf[this] >= tokens);
        
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        Transfer(this, msg.sender, tokens);
    }
    
    function () payable {
        buyTokens(msg.value, now);
    }
    
    function finalizeIco(uint256 _timestamp) internal returns (bool) {
        if (_timestamp > icoEnd) {
            uint256 remainingTokens = balanceOf[this];
            balanceOf[owner] += remainingTokens;
            balanceOf[this] = 0;
            Transfer(this, owner, remainingTokens);
            IcoFinished();
            locked = true;
            return true;
        }
        return false;
    }
    
    function finishIco() onlyOwner {
        finalizeIco(now);
    }
    
    function withdrawEther() onlyOwner {
        owner.transfer(this.balance);
    }
    
    function setRate(uint256 _rate) onlyOwner {
        rate = _rate;
    }
    
    function setLocked(bool _locked) onlyOwner {
        locked = _locked;
    }
    
    uint256 public icoStart;
    uint256 public icoEnd;
    uint256 public totalSupply;
    
    function ERC20Token(
        uint256 _totalSupply,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        uint256 _icoStart,
        uint256 _icoEnd
    ) {
        balanceOf[this] = _totalSupply;
        totalSupply = _totalSupply;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
        icoStart = _icoStart;
        icoEnd = _icoEnd;
        locked = false;
    }
}
```