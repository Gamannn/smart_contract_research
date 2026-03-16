pragma solidity ^0.4.18;

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        uint256 c = a - b;
        return c;
    }
    
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract ERC20Token is ERC20Interface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function transfer(address to, uint256 tokens) public returns (bool success) {
        if (balances[msg.sender] >= tokens && tokens > 0) {
            balances[msg.sender] -= tokens;
            balances[to] += tokens;
            Transfer(msg.sender, to, tokens);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        if (balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens > 0) {
            balances[to] += tokens;
            balances[from] -= tokens;
            allowed[from][msg.sender] -= tokens;
            Transfer(from, to, tokens);
            return true;
        } else {
            return false;
        }
    }
    
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
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

contract ACI is SafeMath, ERC20Token, Pausable {
    string public constant name = "ACI Token";
    string public constant symbol = "ACI";
    uint8 public constant decimals = 18;
    
    event CreateACI(address indexed to, uint256 tokens);
    event PriceChanged(string description, uint price);
    event StageChanged(string description);
    event Withdraw(address to, uint amount);
    
    struct TokenData {
        uint256 totalRaised;
        uint256 tokenPriceWei;
        uint256 hardCap;
        uint256 decimals;
        bool paused;
        address owner;
        uint256 totalSupply;
    }
    
    TokenData public tokenData = TokenData(0, 700 * 10**12, 20000000 * 10**18, 18, false, address(0), 0);
    
    function ACI() public {
    }
    
    function() public payable {
        buyTokens();
    }
    
    function buyTokens() internal whenNotPaused {
        uint multiplier = 10 ** 10;
        uint256 tokens = safeDiv(msg.value * 100000000, tokenData.tokenPriceWei) * multiplier;
        uint256 newTotalSupply = safeAdd(tokenData.totalSupply, tokens);
        
        if (newTotalSupply <= tokenData.hardCap) {
            processPurchase(tokens);
        } else {
            revert();
        }
    }
    
    function processPurchase(uint256 tokens) internal {
        if (msg.value <= 0) revert();
        
        balances[msg.sender] += tokens;
        tokenData.totalSupply = safeAdd(tokenData.totalSupply, tokens);
        tokenData.totalRaised += msg.value;
        CreateACI(msg.sender, tokens);
    }
    
    function withdraw(address to, uint amount) external onlyOwner {
        require(to != address(0));
        to.transfer(amount);
        Withdraw(to, amount);
    }
    
    function setTokenPrice(uint256 newPrice) external onlyOwner {
        tokenData.tokenPriceWei = newPrice;
        PriceChanged("New price set", newPrice);
    }
    
    function mint(address to, uint256 tokens) external onlyOwner {
        require(to != address(0));
        balances[to] += tokens;
        tokenData.totalSupply = safeAdd(tokenData.totalSupply, tokens);
        CreateACI(to, tokens);
    }
}