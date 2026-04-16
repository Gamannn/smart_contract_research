```solidity
pragma solidity ^0.4.13;

contract ERC20Interface {
    function balanceOf(address tokenOwner) constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) returns (bool success);
    function approve(address spender, uint256 tokens) returns (bool success);
    function allowance(address tokenOwner, address spender) constant returns (uint256 remaining);
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event LogTransaction(address indexed sender, uint256 amount);
}

contract ERC20Token is ERC20Interface {
    mapping (address => uint256) balances;
    mapping (address => uint256) contributions;
    mapping (address => mapping (address => uint256)) allowed;
    
    function allowance(address tokenOwner, address spender) constant returns (uint256) {
        return allowed[tokenOwner][spender];
    }
    
    function balanceOf(address tokenOwner) constant returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint256 tokens) returns (bool success) {
        if(msg.data.length < (2 * 32) + 4) {
            revert();
        }
        if (balances[msg.sender] >= tokens && tokens >= 0) {
            balances[msg.sender] -= tokens;
            balances[to] += tokens;
            Transfer(msg.sender, to, tokens);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 tokens) returns (bool success) {
        if(msg.data.length < (3 * 32) + 4) {
            revert();
        }
        if (balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens >= 0) {
            balances[to] += tokens;
            balances[from] -= tokens;
            allowed[from][msg.sender] -= tokens;
            Transfer(from, to, tokens);
            return true;
        } else {
            return false;
        }
    }
    
    function approve(address spender, uint256 tokens) returns (bool success) {
        if (tokens != 0 && allowed[msg.sender][spender] != 0) {
            return false;
        }
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
}

contract GATToken is ERC20Token {
    address owner = msg.sender;
    
    function name() constant returns (string) {
        return "GAT";
    }
    
    uint256 public constant decimals = 18;
    bool public purchasingAllowed;
    uint256 public deadline;
    
    uint256 public totalSupply = 0;
    uint256 public tokenCreationCap = 750 * (10**6) * 10**decimals;
    uint256 public tokenExchangeRate = 1000;
    uint256 public tokenSaleMin = 250 * (10**6) * 10**decimals;
    uint256 public transactionCounter = 0;
    uint256 public startTime = now;
    uint256 public gatFund = 0;
    uint256 public gatFoundDeposit = 0;
    address public gatFoundDepositAddress = address(0);
    address public etherHome = address(0);
    
    uint256 public totalContributed = 0;
    uint256 public totalBonusTokensIssued = 0;
    uint256 public totalRefundable = 0;
    
    function calculateBonus(uint256 amount) internal returns (uint256) {
        uint256 bonus = 0;
        if (transactionCounter > 0 && transactionCounter <= 1000) {
            return amount / 2;
        }
        if (transactionCounter > 1000 && transactionCounter <= 2000) {
            return amount / 5;
        }
        if (transactionCounter > 2000 && transactionCounter <= 3000) {
            return amount / 10;
        }
        if (transactionCounter > 3000 && transactionCounter <= 4000) {
            return amount / 20;
        }
        return amount;
    }
    
    function enablePurchasing() {
        if (msg.sender != owner) {
            revert();
        }
        if(purchasingAllowed) {
            revert();
        }
        purchasingAllowed = true;
    }
    
    function disablePurchasing() {
        if (msg.sender != owner) {
            revert();
        }
        if(!purchasingAllowed) {
            revert();
        }
        purchasingAllowed = false;
    }
    
    function getStats() constant returns (uint256, uint256, bool) {
        return (totalSupply, totalBonusTokensIssued, purchasingAllowed);
    }
    
    function createTokens() payable {
        if (!purchasingAllowed) {
            revert();
        }
        if ((tokenCreationCap - (totalContributed + gatFund)) <= 0) {
            revert();
        }
        if (msg.value == 0) {
            revert();
        }
        
        transactionCounter += 1;
        uint256 tokensIssued = msg.value * tokenExchangeRate;
        uint256 bonusTokens = calculateBonus(tokensIssued);
        uint256 totalTokens = tokensIssued + bonusTokens;
        
        totalContributed += msg.value;
        totalBonusTokensIssued += bonusTokens;
        totalSupply += totalTokens;
        balances[msg.sender] += totalTokens;
        
        Transfer(address(this), msg.sender, totalTokens);
    }
    
    function allocateRemainingTokens() {
        if (purchasingAllowed) {
            revert();
        }
        if (msg.sender != owner) {
            revert();
        }
        uint256 remainingTokens = tokenCreationCap - (totalContributed + gatFund);
        if(remainingTokens <= 0) {
            revert();
        }
        balances[gatFoundDepositAddress] += remainingTokens;
        Transfer(address(this), gatFoundDepositAddress, remainingTokens);
    }
    
    function withdrawEtherHome() external {
        if(purchasingAllowed) {
            revert();
        }
        if (msg.sender != owner) {
            revert();
        }
        etherHome.transfer(this.balance);
    }
    
    function refund() public {
        if(purchasingAllowed) {
            revert();
        }
        if(now >= deadline) {
            revert();
        }
        if((totalContributed - totalBonusTokensIssued) < tokenSaleMin) {
            revert();
        }
        if(contributions[msg.sender] <= 0) {
            revert();
        }
        
        uint256 refundAmount = contributions[msg.sender];
        LogTransaction(msg.sender, refundAmount);
        msg.sender.transfer(refundAmount);
        totalRefundable -= refundAmount;
        contributions[msg.sender] -= refundAmount;
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    function getStrFunc(uint256 index) internal view returns(string storage) {
        return _string_constant[index];
    }
    
    function getBoolFunc(uint256 index) internal view returns(bool) {
        return _bool_constant[index];
    }
    
    uint256[] public _integer_constant = [5000, 5, 86400, 18, 6, 45, 3, 2000, 32, 10, 3000, 2592000, 9000, 4, 1000, 250, 17, 2, 20, 750, 1, 0];
    string[] public _string_constant = ["GAT", "General Advertising Token"];
    bool[] public _bool_constant = [false, true];
}
```