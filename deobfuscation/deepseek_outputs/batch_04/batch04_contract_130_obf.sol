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
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Token is Ownable {
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public freezeOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    
    constructor(
        string tokenName,
        string tokenSymbol,
        address initialOwner
    ) public {
        decimals = 18;
        totalSupply = 1000000000 * 10 ** uint(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        owner = initialOwner;
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(to != address(0));
        require(value > 0);
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        require(value > 0);
        require(balanceOf[msg.sender] >= value);
        
        allowance[msg.sender][spender] = value;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(to != address(0));
        require(value > 0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(value <= allowance[from][msg.sender]);
        
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function burn(uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        require(value > 0);
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(msg.sender, value);
        return true;
    }
    
    function freeze(uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        require(value > 0);
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        freezeOf[msg.sender] = freezeOf[msg.sender].add(value);
        emit Freeze(msg.sender, value);
        return true;
    }
    
    function unfreeze(uint256 value) public returns (bool success) {
        require(freezeOf[msg.sender] >= value);
        require(value > 0);
        
        freezeOf[msg.sender] = freezeOf[msg.sender].sub(value);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(value);
        emit Unfreeze(msg.sender, value);
        return true;
    }
    
    function withdrawEther(uint256 amount) onlyOwner public {
        msg.sender.transfer(amount);
    }
    
    function() external payable {
    }
}
```