```solidity
pragma solidity ^0.4.22;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract ERC20Basic {
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function totalSupply() constant external returns (uint256 totalSupply);
    function balanceOf(address who) constant external returns (uint256 balance);
}

contract TrekToken is ERC20 {
    using SafeMath for uint256;
    
    address owner = msg.sender;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public blacklist;
    
    string public constant name = "TREK";
    string public constant symbol = "TREK";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1200000000e18;
    uint256 public totalDistributed = 0;
    uint256 public totalRemaining = totalSupply.sub(totalDistributed);
    uint256 public value = 7200e18;
    bool public distributionFinished = false;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event Burn(address indexed burner, uint256 value);
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyWhitelist() {
        require(blacklist[msg.sender] == false);
        _;
    }
    
    function TrekToken() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function distribute(address to, uint256 amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(amount);
        totalRemaining = totalRemaining.sub(amount);
        balances[to] = balances[to].add(amount);
        emit Distr(to, amount);
        emit Transfer(address(0), to, amount);
        
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
        return true;
    }
    
    function () external payable {
        getTokens();
    }
    
    function getTokens() payable canDistr onlyWhitelist public {
        if (value > totalRemaining) {
            value = totalRemaining;
        }
        
        require(value <= totalRemaining);
        
        address investor = msg.sender;
        uint256 toGive = value;
        
        distribute(investor, toGive);
        
        if (toGive > 0) {
            blacklist[investor] = true;
        }
        
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
        
        value = value.mul(99999).div(100000);
    }
    
    function balanceOf(address who) constant public returns (uint256) {
        return balances[who];
    }
    
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address to, uint256 amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        require(to != address(0));
        require(amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        require(to != address(0));
        require(amount <= balances[from]);
        require(amount <= allowed[from][msg.sender]);
        
        balances[from] = balances[from].sub(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(from, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool success) {
        if (amount != 0 && allowed[msg.sender][spender] != 0) {
            return false;
        }
        
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) constant public returns (uint256) {
        return allowed[owner][spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint) {
        Token token = Token(tokenAddress);
        uint balance = token.balanceOf(who);
        return balance;
    }
    
    function withdraw() onlyOwner public {
        uint256 etherBalance = address(this).balance;
        owner.transfer(etherBalance);
    }
    
    function burn(uint256 amount) onlyOwner public {
        require(amount <= balances[msg.sender]);
        
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(amount);
        totalSupply = totalSupply.sub(amount);
        totalDistributed = totalDistributed.sub(amount);
        emit Burn(burner, amount);
    }
    
    function withdrawForeignTokens(address tokenAddress) onlyOwner public returns (bool) {
        Token token = Token(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}
```