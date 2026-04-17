```solidity
pragma solidity ^0.5.11;

contract Ownable {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    address payable public owner;
    address payable public pendingOwner;
    
    function transferOwnership(address payable newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }
    
    function claimOwnership() public {
        if (msg.sender == pendingOwner) {
            owner = pendingOwner;
        }
    }
}

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Ownable, ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(
            balances[msg.sender] >= amount &&
            amount > 0 &&
            balances[recipient] + amount > balances[recipient]
        );
        
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(
            balances[sender] >= amount &&
            allowances[sender][msg.sender] >= amount &&
            amount > 0 &&
            balances[recipient] + amount > balances[recipient]
        );
        
        balances[sender] -= amount;
        allowances[sender][msg.sender] -= amount;
        balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }
}

contract BOTToken is ERC20 {
    constructor() public {
        name = "BOT";
        symbol = "BOT";
        decimals = 8;
        totalSupply = 0;
        owner = msg.sender;
    }
    
    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }
    
    function withdraw(uint256 amount) public returns (bool) {
        require(
            amount > 0 &&
            balances[msg.sender] >= amount &&
            amount * block.number <= address(this).balance
        );
        
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        
        uint256 withdrawalAmount = amount * block.number;
        uint256 fee = withdrawalAmount * 1 / 100;
        
        msg.sender.transfer(withdrawalAmount - fee);
        owner.transfer(fee);
        
        return true;
    }
    
    function() payable external {
        if (msg.value > 0) {
            uint256 tokens = msg.value / block.number;
            totalSupply += tokens;
            balances[msg.sender] += tokens;
        }
    }
}
```