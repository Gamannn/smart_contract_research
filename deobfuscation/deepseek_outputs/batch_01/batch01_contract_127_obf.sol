pragma solidity ^0.4.18;

contract UPT {
    string public name;
    string public symbol;
    string public version = 'Token 0.1';
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    struct TokenData {
        uint256 lastBlock;
        uint256 sellPrice;
        uint256 buyPrice;
        uint256 totalSupply;
        uint8 decimals;
    }
    
    TokenData public tokenData = TokenData(0, 0, 0, 0, 0);
    
    function UPT() public {
        name = "UPT";
        symbol = "UPT";
        tokenData.decimals = 15;
        tokenData.totalSupply = 0;
        tokenData.buyPrice = 100000000;
    }
    
    function transfer(address _to, uint256 _value) public {
        if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        
        uint256 price = 0;
        uint256 amount = 0;
        
        if (_to == address(this)) {
            if (tokenData.lastBlock < (block.number - 5000)) {
                price = this.balance * 1000000000 / tokenData.totalSupply;
                amount = (_value * price) / 1000000000;
            } else {
                amount = (_value * tokenData.sellPrice) / 1000000000;
            }
            
            balanceOf[msg.sender] -= _value;
            tokenData.totalSupply -= _value;
            
            if (tokenData.totalSupply != 0) {
                price = (this.balance - amount) * 1000000000 / tokenData.totalSupply;
                tokenData.sellPrice = (price * 900) / 1000;
                tokenData.buyPrice = (price * 1100) / 1000;
            } else {
                tokenData.sellPrice = 0;
                tokenData.buyPrice = 100000000;
            }
            
            if (!msg.sender.send(amount)) revert();
            Transfer(msg.sender, 0x0, _value);
        } else {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            Transfer(msg.sender, _to, _value);
        }
    }
    
    function approve(address _spender, uint256 _value) public returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        if (balanceOf[_from] < _value) revert();
        if ((balanceOf[_to] + _value) < balanceOf[_to]) revert();
        if (_value > allowance[_from][msg.sender]) revert();
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    function() internal payable {
        if (msg.value < 10000000000) revert();
        
        tokenData.lastBlock = block.number;
        uint256 amount = (msg.value / tokenData.buyPrice) * 1000000000;
        
        balanceOf[msg.sender] += amount;
        tokenData.totalSupply += amount;
        
        uint256 price = this.balance * 1000000000 / tokenData.totalSupply;
        tokenData.sellPrice = price * 900 / 1000;
        tokenData.buyPrice = price * 1100 / 1000;
        
        Transfer(0x0, msg.sender, amount);
    }
}