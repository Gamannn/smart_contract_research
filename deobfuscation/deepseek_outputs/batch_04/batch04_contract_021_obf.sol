```solidity
pragma solidity ^0.4.18;

contract SafeMath {
    function SafeMath() public {}
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }
    
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ERC20Burnable is ERC20Interface {
    function burn(uint tokens) public;
    function burnTokens(uint tokens) public;
}

contract Token is ERC20Burnable, SafeMath {
    event PaymentEvent(address indexed from, uint amount);
    event TransferEvent(address indexed from, address indexed to, uint tokens);
    event ApprovalEvent(address indexed owner, address indexed spender, uint tokens);
    event BurnEvent(address indexed from, uint tokenAmount, uint ethAmount);
    
    string public name;
    string public symbol;
    bool public isLocked;
    uint public decimals;
    
    address public owner;
    address public restrictedAccount;
    uint public tokenSupply;
    uint public restrictUntil;
    uint public totalEthBalance;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier notLocked {
        require(!isLocked);
        _;
    }
    
    modifier restricted {
        require((msg.sender == restrictedAccount) || (now >= restrictUntil));
        _;
    }
    
    function Token() public {
        owner = msg.sender;
        restrictedAccount = address(0);
        isLocked = true;
    }
    
    function transfer(address to, uint tokens) public restricted returns (bool success) {
        if (balances[msg.sender] >= tokens && tokens > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            TransferEvent(msg.sender, to, tokens);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if (balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens > 0) {
            balances[from] = safeSub(balances[from], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            TransferEvent(from, to, tokens);
            return true;
        } else {
            return false;
        }
    }
    
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        balance = balances[tokenOwner];
    }
    
    function approve(address spender, uint tokens) public restricted returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        ApprovalEvent(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function () public payable {
        PaymentEvent(msg.sender, msg.value);
    }
    
    function initialize(uint initialSupply, uint decimalUnits) public onlyOwner {
        require(tokenSupply == 0);
        tokenSupply = initialSupply;
        balances[owner] = tokenSupply;
        decimals = decimalUnits;
    }
    
    function setNameSymbol(string tokenName, string tokenSymbol) public onlyOwner {
        name = tokenName;
        symbol = tokenSymbol;
    }
    
    function unlock() public onlyOwner {
        isLocked = false;
    }
    
    function restrictAccount(address restrictedAcct, uint restrictionTime) public onlyOwner notLocked {
        restrictedAccount = restrictedAcct;
        restrictUntil = restrictionTime;
    }
    
    function totalSupply() public constant returns (uint tokens) {
        tokens = this.balanceOf(address(this)) / tokenSupply;
    }
    
    function ethBalance(address account) public constant returns (uint amount) {
        amount = (totalEthBalance * balances[account]) / tokenSupply;
    }
    
    function burn(uint tokens) public restricted {
        if (balances[msg.sender] >= tokens && tokens > 0) {
            uint ethAmount = safeMul(this.balanceOf(address(this)), tokens) / tokenSupply;
            tokenSupply = safeSub(tokenSupply, tokens);
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            msg.sender.transfer(ethAmount);
            BurnEvent(msg.sender, tokens, ethAmount);
        }
    }
    
    function burnTokens(uint tokens) public restricted {
        if (balances[msg.sender] >= tokens && tokens > 0) {
            tokenSupply = safeSub(tokenSupply, tokens);
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            BurnEvent(msg.sender, tokens, 0);
        }
    }
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}
```