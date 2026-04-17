```solidity
pragma solidity ^0.4.11;

contract ERC20Interface {
    function totalSupply() constant returns (uint256);
    function balanceOf(address tokenOwner) constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) returns (bool success);
    function approve(address spender, uint256 tokens) returns (bool success);
    function allowance(address tokenOwner, address spender) constant returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function max(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }
    
    function min(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }
    
    function max(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }
    
    function min(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

contract E93Token is ERC20Interface {
    using SafeMath for uint256;
    
    modifier onlyOwner() {
        require(msg.sender == 0x3a31AC87092909AF0e01B4d8fC6E03157E91F4bb || msg.sender == 0x44fc3);
        _;
    }
    
    uint256 public totalSupply;
    uint256 public maxSupply;
    bool public saleActive;
    uint8 public decimals = 18;
    string public name = "ETH93";
    string public symbol = "E93";
    
    address public e93Contract;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    function E93Token() {
        saleActive = true;
        maxSupply = 393835582055537122839628650862841990523569990749;
    }
    
    function stopSale() onlyOwner {
        saleActive = false;
    }
    
    function setE93Contract(address _e93Contract) onlyOwner {
        require(saleActive);
        e93Contract = _e93Contract;
    }
    
    function() payable {
        if (msg.sender != e93Contract) {
            buyTokens();
        }
    }
    
    function contractBalance() public constant returns (uint256) {
        return this.balance;
    }
    
    function withdrawTokens() {
        uint256 userPortion = (balances[msg.sender].mul(this.balance)).div(maxSupply);
        totalSupply = totalSupply.sub(balances[msg.sender]);
        balances[msg.sender] = 0;
        msg.sender.transfer(userPortion);
    }
    
    function getUserPortion() constant returns (uint256 userPortion) {
        userPortion = (balances[msg.sender].mul(this.balance)).div(maxSupply);
        return userPortion;
    }
    
    function fundContract() payable {
        // Empty function - accepts ETH
    }
    
    function buyTokens() payable {
        require(msg.value > 0);
        if (saleActive != true) revert();
        
        uint256 tokens = msg.value.mul(decimals);
        
        if (totalSupply.add(tokens) > maxSupply) {
            uint256 availableTokens = totalSupply.add(tokens).sub(maxSupply);
            balances[msg.sender] = balances[msg.sender].add(maxSupply.sub(totalSupply));
            totalSupply = maxSupply;
            msg.sender.transfer(msg.value.sub(availableTokens.div(decimals)));
        } else {
            totalSupply = totalSupply.add(tokens);
            balances[msg.sender] = balances[msg.sender].add(tokens);
            e93Contract.transfer(msg.value);
        }
    }
    
    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address tokenOwner) constant returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint256 tokens) returns (bool success) {
        require(balances[msg.sender] >= tokens && tokens > 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) returns (bool success) {
        require(allowed[from][msg.sender] >= tokens && balances[from] >= tokens && tokens > 0);
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    
    function approve(address spender, uint256 tokens) returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}
```