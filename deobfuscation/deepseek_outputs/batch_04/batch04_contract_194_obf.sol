```solidity
pragma solidity ^0.5.0;

contract STK {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    uint256 private _rate;
    
    constructor() public {
        _rate = 0.006 ether;
        _totalSupply = 0;
    }
    
    function name() public pure returns (string memory) {
        return "STK";
    }
    
    function symbol() public pure returns (string memory) {
        return "STK";
    }
    
    function decimals() public pure returns (uint8) {
        return 18;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(_balances[msg.sender] >= amount);
        
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function buy(uint256 amount) payable public {
        require(msg.value >= _rate * amount);
        
        _totalSupply += amount;
        _balances[msg.sender] += amount;
    }
    
    function burn(uint256 amount) public returns (bool) {
        require(_balances[msg.sender] >= amount);
        
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        
        return true;
    }
}
```