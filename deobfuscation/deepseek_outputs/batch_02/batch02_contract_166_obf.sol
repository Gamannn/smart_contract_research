```solidity
pragma solidity ^0.4.24;

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public price;
    uint256 public totalSupply;
    address public owner;
    
    mapping(address => uint256) public balanceOf;
    
    event Burn(address indexed burner, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdraw(address to, uint amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier validAddress(address addr) {
        require(addr != address(0));
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        name = "Ox6c8a9f512c942ee2af1fc10f05d6e0f177fde60d";
        symbol = "Ox6c8a9f512c942ee2af1fc10f05d6e0f177fde60d";
        decimals = 18;
        price = 50;
        totalSupply = 10000 * 10**uint256(decimals);
        balanceOf[owner] = totalSupply;
    }
    
    function setName(string _name) onlyOwner public returns (string) {
        name = _name;
        return name;
    }
    
    function setPrice(uint256 _price) onlyOwner public returns (uint256) {
        price = _price;
        return price;
    }
    
    function setDecimals(uint256 _decimals) onlyOwner public returns (uint256) {
        decimals = uint8(_decimals);
        return decimals;
    }
    
    function balanceOf(address _owner) public view returns(uint256) {
        return balanceOf[_owner];
    }
    
    function getOwner() view public returns(address) {
        return owner;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal validAddress(_to) {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function() public payable {
        uint256 tokens = (msg.value * price) / 10**uint256(decimals);
        
        if(msg.sender == owner) {
            totalSupply += tokens;
            balanceOf[owner] += tokens;
        } else {
            require(balanceOf[owner] >= tokens);
            _transfer(owner, msg.sender, tokens);
        }
    }
    
    function mint(uint256 _value) public onlyOwner returns (bool success) {
        totalSupply += _value;
        balanceOf[owner] += _value;
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function withdrawAll() onlyOwner {
        msg.sender.transfer(address(this).balance);
        emit Withdraw(msg.sender, address(this).balance);
    }
    
    function withdraw(uint amount) external onlyOwner {
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }
    
    function withdrawTo(address _to, uint amount) external onlyOwner validAddress(_to) {
        _to.transfer(amount);
        uint fee = amount / 100;
        msg.sender.transfer(fee);
    }
}
```