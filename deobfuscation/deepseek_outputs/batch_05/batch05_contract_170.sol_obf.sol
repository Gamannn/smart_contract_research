```solidity
pragma solidity 0.4.18;

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal returns(uint256) {
        uint256 c = a + b;
        assert((c >= a) && (c >= b));
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal returns(uint256) {
        assert(a >= b);
        uint256 c = a - b;
        return c;
    }
    
    function safeMul(uint256 a, uint256 b) internal returns(uint256) {
        uint256 c = a * b;
        assert((a == 0) || (c / a == b));
        return c;
    }
}

contract ERC20 {
    uint256 public totalSupply;
    
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    function allowance(address owner, address spender) constant returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20 {
    function transfer(address to, uint256 value) returns (bool) {
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 value) returns (bool) {
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
    
    function balanceOf(address who) constant returns (uint256) {
        return balances[who];
    }
    
    function approve(address spender, uint256 value) returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) constant returns (uint256) {
        return allowed[owner][spender];
    }
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract Ownable {
    address public owner;
    
    function Ownable() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract GLXCoin is StandardToken, Ownable, SafeMath {
    string public constant name = "GLXCoin";
    string public constant symbol = "GLXC";
    uint256 public constant decimals = 18;
    string public version = "1.0";
    
    address public ethFundDeposit;
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public tokenCreationCap;
    uint256 public tokenExchangeRate;
    uint256 public tokenCreationMin;
    
    bool public isFinalized;
    uint256 public totalSupply;
    
    event CreateGLX(address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    
    function GLXCoin() {
        isFinalized = false;
        fundingStartBlock = block.number;
        fundingEndBlock = safeAdd(fundingStartBlock, 169457);
        tokenCreationCap = 360711 * (10 ** decimals);
        tokenExchangeRate = 700;
        tokenCreationMin = 875 * (10 ** decimals);
        ethFundDeposit = 0xeE9b66740EcF1a3e583e61B66C5b8563882b5d12;
        totalSupply = 0;
        owner = msg.sender;
    }
    
    function createTokens() internal {
        if (isFinalized) revert();
        if (block.number > fundingEndBlock) revert();
        if (msg.value < (1 ether / 100)) revert();
        
        uint256 tokens = safeMul(msg.value, tokenExchangeRate);
        tokens = safeAdd(tokens, (10 ** decimals) / 2);
        
        if (tokens > tokenCreationCap) revert();
        
        balances[msg.sender] += tokens;
        totalSupply = safeAdd(totalSupply, tokens);
        CreateGLX(msg.sender, tokens);
    }
    
    function buy() payable external {
        createTokens();
    }
    
    function mint(address to, uint256 value) external onlyOwner returns (bool) {
        if (isFinalized) revert();
        
        totalSupply = safeAdd(totalSupply, value);
        
        if (totalSupply > tokenCreationCap) revert();
        
        balances[to] += value;
        Mint(to, value);
        return true;
    }
    
    function changeEndBlock(uint256 _newBlock) onlyOwner returns (uint256) {
        require(_newBlock > fundingStartBlock);
        fundingEndBlock = _newBlock;
        return fundingEndBlock;
    }
    
    function drain() external onlyOwner {
        if (!ethFundDeposit.send(this.balance)) revert();
    }
    
    function toggleContribution() external onlyOwner {
        isFinalized = !isFinalized;
    }
    
    function() payable {
        createTokens();
    }
}
```