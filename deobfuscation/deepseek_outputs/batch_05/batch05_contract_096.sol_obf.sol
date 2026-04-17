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
    
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract Token is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    uint256 public buyPrice = 1000000000000;
    uint256 public duration = 259200;
    bool public closed = false;
    
    uint256 public deadline;
    uint256 public amountRaised;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    function Token() public {
        totalSupply = 1000000 * 10 ** uint256(decimals);
        balanceOf[this] = 1000000 * 8 * (10 ** uint256(decimals - 1));
        balanceOf[msg.sender] = 1000000 * 2 * (10 ** uint256(decimals - 1));
        name = "Token";
        symbol = "DUDE";
        buyPrice = 1000000000000;
        amountRaised = 0;
        deadline = now + duration * 1 minutes;
    }
    
    modifier afterDeadline() {
        require(now >= deadline);
        _;
    }
    
    function closeSale() public afterDeadline {
        owner.transfer(amountRaised);
        amountRaised = 0;
        closed = true;
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
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
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
    
    function setPrices(uint256 newBuyPrice) public onlyOwner {
        buyPrice = newBuyPrice;
    }
    
    function () payable public {
        require(!closed);
        uint256 amount = (msg.value * 1 ether) / buyPrice;
        require(balanceOf[this] >= amount);
        balanceOf[msg.sender] += amount;
        balanceOf[this] -= amount;
        Transfer(this, msg.sender, amount);
        amountRaised += msg.value;
        
        if (amountRaised >= 0.5 * 1 ether) {
            owner.transfer(amountRaised);
            amountRaised = 0;
        }
    }
    
    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOf[_owner];
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }
}
```