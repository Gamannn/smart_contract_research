```solidity
pragma solidity ^0.4.24;

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

contract ERC20Interface {
    function transfer(address to, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract Ownable {
    address public owner;
    
    constructor() internal {
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

contract Token is ERC20Interface, Ownable {
    using SafeMath for uint256;
    
    string public name = "CIP Token";
    string public symbol = "CIP";
    uint256 public decimals = 18;
    uint256 public totalSupply = 4500000000 * (10 ** 18);
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public frozenAmount;
    
    event FreezeIn(address[] indexed addresses, bool status);
    event FreezeOut(address[] indexed addresses, bool status);
    
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function internalTransfer(address from, address to, uint value) internal {
        require(to != address(0));
        require(balanceOf[from] >= value);
        
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        
        emit Transfer(from, to, value);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balanceOf[msg.sender]);
        
        uint256 availableBalance = balanceOf[msg.sender].sub(frozenAmount[msg.sender]);
        require(value <= availableBalance);
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(allowance[from][msg.sender] >= value);
        
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        internalTransfer(from, to, value);
        
        return true;
    }
    
    function setNameSymbol(string _name, string _symbol) public onlyOwner {
        name = _name;
        symbol = _symbol;
    }
    
    function freeze(address account, uint256 amount) public onlyOwner {
        require(account != address(0));
        frozenAmount[account] = frozenAmount[account].add(amount);
    }
    
    function unfreeze(address account, uint256 amount) public onlyOwner {
        require(account != address(0));
        require(amount <= frozenAmount[account]);
        frozenAmount[account] = frozenAmount[account].sub(amount);
    }
    
    function() public payable {
    }
}
```