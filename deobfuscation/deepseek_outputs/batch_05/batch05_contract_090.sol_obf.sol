pragma solidity ^0.4.10;

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
    
    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
}

contract Token {
    uint256 public totalSupply;
    
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is Token {
    function transfer(address to, uint256 value) returns (bool success) {
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 value) returns (bool success) {
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
    
    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }
    
    function approve(address spender, uint256 value) returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract MNDToken is SafeMath, StandardToken {
    string public constant name = "MNDToken";
    string public constant symbol = "MND";
    uint256 public constant decimals = 18;
    
    enum Phase {
        PreICO1,
        PreICO2,
        ICO
    }
    
    Phase public currentPhase = Phase.PreICO1;
    
    address public owner;
    address public wallet;
    
    uint256 public tokenCreationCapPreICO1 = 5000000 * 10**decimals;
    uint256 public tokenCreationCapPreICO2 = 6000000 * 10**decimals;
    uint256 public tokenCreationCap = 12500000 * 10**decimals;
    
    uint256 public oneTokenInWeiPreICO1 = 5473684210526320;
    uint256 public oneTokenInWeiPreICO2 = 526315789473684;
    uint256 public oneTokenInWeiICO = 0;
    
    event CreateMND(address indexed to, uint256 value);
    
    function MNDToken() {
        owner = msg.sender;
        wallet = 0x0077DA9DF6507655CDb3aB9277A347EDe759F93F;
    }
    
    function () payable {
        createTokens();
    }
    
    function createTokens() internal {
        if (msg.value <= 0) revert();
        
        uint256 oneTokenInWei = getCurrentRate();
        uint256 multiplier = 10 ** decimals;
        uint256 tokens = safeDiv(msg.value, oneTokenInWei) * multiplier;
        uint256 checkedSupply = safeAdd(totalSupply, tokens);
        
        if (tokenCreationCap <= checkedSupply) revert();
        
        balances[msg.sender] += tokens;
        totalSupply = safeAdd(totalSupply, tokens);
        CreateMND(msg.sender, tokens);
    }
    
    function getCurrentRate() internal view returns (uint256) {
        if (currentPhase == Phase.PreICO1) {
            return oneTokenInWeiPreICO1;
        } else if (currentPhase == Phase.PreICO2) {
            return oneTokenInWeiPreICO2;
        } else {
            return oneTokenInWeiICO;
        }
    }
    
    function startPreICO2() external onlyOwner returns (bool) {
        currentPhase = Phase.PreICO2;
        return true;
    }
    
    function startICO() external onlyOwner returns (bool) {
        currentPhase = Phase.ICO;
        return true;
    }
    
    function setRates(uint rate1, uint rate2, uint rate3) external onlyOwner returns (bool) {
        oneTokenInWeiPreICO1 = rate1;
        oneTokenInWeiPreICO2 = rate2;
        oneTokenInWeiICO = rate3;
        return true;
    }
    
    function withdraw() external onlyOwner {
        wallet.transfer(this.balance);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}