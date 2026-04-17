```solidity
pragma solidity ^0.4.23;

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) internal etherBalance;
    
    address public owner;
    uint256 public sellPrice;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    function Token() public {
        totalSupply = 5000000 * 10 ** uint256(18);
        balanceOf[msg.sender] = totalSupply;
        name = "Facebook";
        symbol = "XFBC";
        decimals = 18;
        owner = msg.sender;
        sellPrice = 100;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function buy() public payable returns(uint256) {
        uint256 amount = msg.value;
        return _buy(amount);
    }
    
    function _buy(uint256 _amount) internal returns(uint256) {
        uint256 tokens = _calculateTokens(_amount);
        balanceOf[msg.sender] += tokens;
        etherBalance[owner] += _amount;
        totalSupply += tokens;
        return tokens;
    }
    
    function _calculateTokens(uint256 _etherAmount) internal view returns(uint256) {
        uint256 tokens = SafeMath.div(_etherAmount, sellPrice) * 100;
        return tokens;
    }
    
    function withdraw() public {
        address user = msg.sender;
        uint256 etherAmount = etherBalance[user];
        etherBalance[user] = 0;
        user.transfer(etherAmount);
    }
    
    function getBuyPrice() public view returns(uint256) {
        return sellPrice;
    }
    
    function getSellPrice() public view returns(uint256) {
        return sellPrice;
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
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
```