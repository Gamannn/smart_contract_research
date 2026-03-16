```solidity
pragma solidity ^0.4.18;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256);
    function transfer(address to, uint256 tokens) public returns (bool);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool);
    function allowance(address tokenOwner, address spender) public view returns (uint256);
    function approve(address spender, uint256 tokens) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
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

contract Token is ERC20Interface {
    using SafeMath for uint256;
    
    string public constant name = "BTW";
    string public constant symbol = "Token";
    uint8 public constant decimals = 18;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    address public owner;
    uint256 public rate = 10000;
    uint256 public maxSupply = 22000000 * 10 ** uint256(decimals);
    uint256 public totalSold = 0;
    
    function () public payable {
        buyTokens();
    }
    
    function Token() public {
        owner = msg.sender;
    }
    
    function buyTokens() public payable {
        require(msg.value > 0);
        require(totalSold < maxSupply);
        
        uint256 tokens = msg.value.mul(rate);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        totalSold = totalSold.add(tokens);
    }
    
    function totalSupply() public constant returns (uint256) {
        return totalSold;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(
            allowed[from][msg.sender] >= tokens &&
            balances[from] >= tokens &&
            tokens > 0
        );
        
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    
    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowed[tokenOwner][spender];
    }
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}
```