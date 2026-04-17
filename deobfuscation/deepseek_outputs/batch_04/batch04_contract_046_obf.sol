```solidity
pragma solidity ^0.4.18;

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert((c >= a) && (c >= b));
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(a >= b);
        uint256 c = a - b;
        return c;
    }
    
    function safeMul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert((a == 0) || (c / a == b));
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
}

contract ERC20Interface {
    uint256 public totalSupply;
    
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function balanceOf(address owner) public constant returns (uint256 balance);
    function allowance(address owner, address spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Token is ERC20Interface {
    function transfer(address to, uint256 value) public returns (bool success) {
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function balanceOf(address owner) public constant returns (uint256 balance) {
        return balances[owner];
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

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
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }
    
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

contract ACIToken is SafeMath, ERC20Token, Pausable {
    string public constant name = "ACI Token";
    string public constant symbol = "ACI";
    uint256 public constant decimals = 18;
    
    uint256 public totalRaised;
    uint256 public tokenPrice;
    uint256 public hardCap;
    uint256 public softCap = 20000000;
    
    event CreateACI(address indexed recipient, uint256 tokens);
    event PriceChanged(string message, uint256 newPrice);
    event StageChanged(string message);
    event Withdraw(address recipient, uint256 amount);
    
    function ACIToken() public {
        tokenPrice = 700000000000000000;
        hardCap = 120000000000000000000000000;
    }
    
    function () public payable {
        buyTokens();
    }
    
    function buyTokens() internal whenNotPaused {
        uint256 tokens = safeDiv(msg.value, tokenPrice);
        uint256 checkedSupply = safeAdd(totalSupply, tokens);
        
        if (hardCap <= checkedSupply) {
            mintTokens(tokens);
        } else {
            revert();
        }
    }
    
    function mintTokens(uint256 tokens) internal {
        if (msg.value <= 0) revert();
        
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        totalSupply = safeAdd(totalSupply, tokens);
        totalRaised += msg.value;
        
        CreateACI(msg.sender, tokens);
    }
    
    function withdraw(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0));
        recipient.transfer(amount);
        Withdraw(recipient, amount);
    }
    
    function setPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
        PriceChanged("New price set", newPrice);
    }
    
    function mint(address recipient, uint256 tokens) external onlyOwner {
        require(recipient != address(0));
        balances[recipient] = safeAdd(balances[recipient], tokens);
        totalSupply = safeAdd(totalSupply, tokens);
        CreateACI(recipient, tokens);
    }
}
```