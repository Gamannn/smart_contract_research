```solidity
pragma solidity ^0.4.18;

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
        assert(b > 0);
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
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    address public owner;
    address public newOwner;
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ERC20Token is ERC20Interface, Ownable {
    using SafeMath for uint256;
    
    string public constant symbol = "ast";
    string public constant name = "AllStocks Token";
    uint8 public constant decimals = 18;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) contributions;
    
    function ERC20Token() public {
    }
    
    function totalSupply() public constant returns (uint256) {
        return totalTokens - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != 0x0);
        if (msg.sender != owner) require(tokensTransferable);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function approve(address spender, uint256 tokens) public returns (bool success) {
        require(tokensTransferable);
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        require(tokensTransferable);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        require(tokensTransferable);
        return allowed[tokenOwner][spender];
    }
}

contract AllStocksToken is ERC20Token {
    string public version = "1.0";
    
    event LogRefund(address indexed contributor, uint256 amount);
    event CreateAllstocksToken(address indexed contributor, uint256 amount);
    
    function AllStocksToken() public {
        tokensTransferable = false;
        owner = msg.sender;
        totalTokens = initialSupply;
        balances[owner] = initialSupply;
        CreateAllstocksToken(owner, initialSupply);
    }
    
    function configureCrowdsale(
        uint256 _startTime,
        uint256 _endTime
    ) onlyOwner external {
        require (crowdsaleConfigured == false);
        require (tokensTransferable == false);
        require (msg.sender == owner);
        require (crowdsaleStartTime == 0);
        require (crowdsaleEndTime == 0);
        require(_startTime > 0);
        require(_endTime > 0 && _endTime > _startTime);
        
        tokensTransferable = false;
        crowdsaleConfigured = true;
        crowdsaleWallet = owner;
        crowdsaleStartTime = _startTime;
        crowdsaleEndTime = _endTime;
    }
    
    function () public payable {
        buyTokens(msg.value);
    }
    
    function buyTokens(uint256 amount) internal {
        require(tokensTransferable == false);
        require(now >= crowdsaleStartTime);
        require(now < crowdsaleEndTime);
        require(msg.value > 0);
        
        uint256 tokens = amount.mul(tokensPerEther);
        uint256 newTotalTokens = totalTokens.add(tokens);
        require(newTotalTokens <= crowdsaleHardCap);
        
        totalTokens = newTotalTokens;
        balances[msg.sender] += tokens;
        contributions[msg.sender] = amount.add(contributions[msg.sender]);
        CreateAllstocksToken(msg.sender, tokens);
        Transfer(address(0), owner, totalTokens);
    }
    
    function setTokensPerEther(uint256 rate) external onlyOwner {
        require (tokensTransferable == false);
        require (crowdsaleConfigured == true);
        require (rate > 0);
        require(msg.sender == owner);
        tokensPerEther = rate;
    }
    
    function finalizeCrowdsale() external onlyOwner {
        require (tokensTransferable == false);
        require(msg.sender == owner);
        require(totalTokens >= softCap + initialSupply);
        require(totalTokens > 0);
        
        if (now < crowdsaleEndTime) {
            require(totalTokens >= crowdsaleHardCap);
        } else {
            require(now >= crowdsaleEndTime);
        }
        
        tokensTransferable = true;
        crowdsaleWallet.transfer(this.balance);
    }
    
    function withdrawFunds() external onlyOwner {
        require(msg.sender == owner);
        require(totalTokens >= softCap + initialSupply);
        crowdsaleWallet.transfer(this.balance);
    }
    
    function refund() external {
        require (tokensTransferable == false);
        require (crowdsaleConfigured == true);
        require (now > crowdsaleEndTime);
        require(totalTokens < softCap + initialSupply);
        require(msg.sender != owner);
        
        uint256 tokenBalance = balances[msg.sender];
        uint256 contributionAmount = contributions[msg.sender];
        require(tokenBalance > 0);
        require(contributionAmount > 0);
        
        balances[msg.sender] = 0;
        contributions[msg.sender] = 0;
        totalTokens = totalTokens.sub(tokenBalance);
        
        uint256 refundAmount = tokenBalance / tokensPerEther;
        require(contributionAmount <= refundAmount);
        msg.sender.transfer(contributionAmount);
        LogRefund(msg.sender, contributionAmount);
    }
    
    struct TokenConfig {
        uint256 softCap;
        uint256 crowdsaleHardCap;
        uint256 tokensPerEther;
        uint256 initialSupply;
        uint256 crowdsaleEndTime;
        uint256 crowdsaleStartTime;
        bool crowdsaleConfigured;
        address crowdsaleWallet;
        bool tokensTransferable;
        uint256 totalTokens;
        uint256 decimals;
        address newOwner;
        address owner;
    }
    
    TokenConfig config = TokenConfig(
        25 * (10**5) * 10**decimals,
        50 * (10**6) * 10**decimals,
        625,
        25 * (10**6) * 10**decimals,
        0,
        0,
        false,
        address(0),
        false,
        0,
        18,
        address(0),
        address(0)
    );
    
    uint256 public softCap = config.softCap;
    uint256 public crowdsaleHardCap = config.crowdsaleHardCap;
    uint256 public tokensPerEther = config.tokensPerEther;
    uint256 public initialSupply = config.initialSupply;
    uint256 public crowdsaleEndTime = config.crowdsaleEndTime;
    uint256 public crowdsaleStartTime = config.crowdsaleStartTime;
    bool public crowdsaleConfigured = config.crowdsaleConfigured;
    address public crowdsaleWallet = config.crowdsaleWallet;
    bool public tokensTransferable = config.tokensTransferable;
    uint256 public totalTokens = config.totalTokens;
}
```