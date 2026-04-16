```solidity
pragma solidity ^0.4.26;

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function isOwner(address addr) public view returns(bool) {
        return addr == owner;
    }
    
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}

interface ERC20 {
    function transfer(address to, uint256 value) public returns (bool);
}

contract Token is Ownable {
    string public constant name = "BASS";
    string public constant symbol = "Ox317e9af35425af2610a5c331a6795a2e644e8a20";
    string public constant description = "It's a permanent, perfect SIMULTANEOUS dichotomy of total insignificance and total significance merged as one into every single flashing second.";
    uint8 public constant decimals = 18;
    
    uint256 public totalSupply;
    uint256 public tokensPerEth;
    bool public tradeable;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private blacklist;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ReceivedEth(address indexed sender, uint256 amount, uint256 timestamp);
    event TransferedEth(address indexed recipient, uint256 amount);
    event TransferedERC20(address indexed recipient, address indexed token, uint256 amount);
    event SoldToken(address indexed buyer, uint256 amount, bytes32 data);
    
    modifier notBlacklisted() {
        require(!blacklist[msg.sender]);
        _;
    }
    
    function Token(uint256 initialSupply, uint256 initialTokensPerEth) public {
        totalSupply = initialSupply * (10 ** uint256(decimals));
        balances[this] = initialSupply * (10 ** uint256(decimals));
        tokensPerEth = initialTokensPerEth;
        tradeable = true;
    }
    
    function () public payable {
        ReceivedEth(msg.sender, msg.value, now);
    }
    
    function getTokensPerEth() public view returns(uint256) {
        return tokensPerEth;
    }
    
    function setTokensPerEth(uint256 newRate) public onlyOwner {
        tokensPerEth = newRate;
    }
    
    function buy(bytes32 data) public payable {
        require(msg.value > 0);
        uint256 tokens = ((tokensPerEth * (10 ** uint256(decimals))) * msg.value) / (10 ** 18);
        
        require(balances[this] + tokens > balances[this]);
        
        SoldToken(msg.sender, msg.value, data);
        Transfer(this, msg.sender, tokens);
        
        totalSupply += tokens;
        balances[msg.sender] += tokens;
    }
    
    function addToBlacklist(address addr) public onlyOwner {
        blacklist[addr] = true;
    }
    
    function removeFromBlacklist(address addr) public onlyOwner {
        delete blacklist[addr];
    }
    
    function setTradeable(bool status) public onlyOwner {
        tradeable = status;
    }
    
    function isTradeable() public view returns(bool) {
        return tradeable;
    }
    
    function balanceOf(address addr) public view returns (uint256) {
        return balances[addr];
    }
    
    function transfer(address recipient, uint256 amount) public notBlacklisted returns (bool) {
        require(tradeable);
        
        if (balances[msg.sender] >= amount && 
            amount > 0 && 
            balances[recipient] + amount > balances[recipient]) {
            
            Transfer(msg.sender, recipient, amount);
            balances[msg.sender] -= amount;
            balances[recipient] += amount;
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address recipient, uint256 amount) public notBlacklisted returns (bool) {
        require(!blacklist[from] && !blacklist[recipient]);
        require(tradeable);
        
        if (balances[from] >= amount && 
            allowances[from][msg.sender] >= amount && 
            amount > 0 && 
            balances[recipient] + amount > balances[recipient]) {
            
            Transfer(from, recipient, amount);
            balances[from] -= amount;
            allowances[from][msg.sender] -= amount;
            balances[recipient] += amount;
            return true;
        } else {
            return false;
        }
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        Approval(msg.sender, spender, amount);
        allowances[msg.sender][spender] = amount;
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }
    
    function transferEthAndTokens(address recipient, uint256 ethAmount, uint256 tokenAmount) public onlyOwner {
        require(this.balance >= ethAmount && balances[this] >= tokenAmount);
        
        if (ethAmount > 0) {
            recipient.transfer(ethAmount);
            TransferedEth(recipient, ethAmount);
        }
        
        if (tokenAmount > 0) {
            require(balances[recipient] + tokenAmount > balances[recipient]);
            balances[this] -= tokenAmount;
            balances[recipient] += tokenAmount;
            Transfer(this, recipient, tokenAmount);
        }
    }
    
    function transferERC20(address recipient, address tokenAddress, uint256 amount) internal onlyOwner {
        ERC20 token = ERC20(tokenAddress);
        require(token.transfer(recipient, amount));
        TransferedERC20(recipient, tokenAddress, amount);
    }
}
```