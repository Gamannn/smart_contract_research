```solidity
pragma solidity ^0.5.11;

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Interface {
    function transfer(address to, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value) public returns (bool success);
    function approve(address spender, uint value) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Token is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    address payable public owner;
    address public manager;
    bool public paused = false;
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public frozenBalance;
    
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    event Pause(address indexed caller);
    event Unpause(address indexed caller);
    
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol,
        address managerAddress
    ) public {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        owner = msg.sender;
        manager = managerAddress;
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(!paused, "contract is paused");
        require(to != address(0), "transfer to the zero address");
        require(balanceOf[msg.sender] > value, "balance not enough");
        require(balanceOf[to] + value > balanceOf[to], "overflow");
        
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        require(!paused, "contract is paused");
        require(value > 0);
        
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(!paused, "contract is paused");
        require(to != address(0), "transfer to the zero address");
        require(value > 0);
        require(balanceOf[from] >= value, "the balance of from address not enough");
        require(balanceOf[to] + value > balanceOf[to], "overflow");
        require(value <= allowance[from][msg.sender], "allowance not enough");
        
        balanceOf[from] = safeSub(balanceOf[from], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], value);
        
        emit Transfer(from, to, value);
        return true;
    }
    
    function burn(uint256 value) public returns (bool success) {
        require(!paused, "contract is paused");
        require(balanceOf[msg.sender] >= value, "balance not enough");
        
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        
        emit Burn(msg.sender, value);
        return true;
    }
    
    function freeze(address target, uint256 value) public returns (bool success) {
        require(!paused, "contract is paused");
        require(msg.sender == owner || msg.sender == manager, "no permission");
        require(balanceOf[target] >= value, "balance not enough");
        require(value > 0);
        
        balanceOf[target] = safeSub(balanceOf[target], value);
        frozenBalance[target] = safeAdd(frozenBalance[target], value);
        
        emit Freeze(target, value);
        return true;
    }
    
    function unfreeze(address target, uint256 value) public returns (bool success) {
        require(!paused, "contract is paused");
        require(msg.sender == owner || msg.sender == manager, "no permission");
        require(frozenBalance[target] >= value, "freeze balance not enough");
        require(value > 0);
        
        frozenBalance[target] = safeSub(frozenBalance[target], value);
        balanceOf[target] = safeAdd(balanceOf[target], value);
        
        emit Unfreeze(target, value);
        return true;
    }
    
    function withdraw(uint256 amount) public {
        require(msg.sender == owner, "no permission");
        owner.transfer(amount);
    }
    
    function() external payable {
    }
    
    function pause() public {
        require(msg.sender == owner || msg.sender == manager, "no permission");
        paused = true;
        emit Pause(msg.sender);
    }
    
    function unpause() public {
        require(msg.sender == owner || msg.sender == manager, "no permission");
        paused = false;
        emit Unpause(msg.sender);
    }
}
```