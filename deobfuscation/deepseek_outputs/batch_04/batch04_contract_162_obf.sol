```solidity
pragma solidity ^0.4.19;

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

contract ERC20Token is ERC20Interface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function transfer(address to, uint256 tokens) returns (bool success) {
        if (balances[msg.sender] >= tokens && tokens > 0) {
            balances[msg.sender] -= tokens;
            balances[to] += tokens;
            Transfer(msg.sender, to, tokens);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 tokens) returns (bool success) {
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
    
    function balanceOf(address tokenOwner) constant returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function approve(address spender, uint256 tokens) returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
}

contract JAVToken is ERC20Token {
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version;
    uint256 public totalSupply;
    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;
    address public fundsWallet;
    
    function JAVToken() {
        balances[msg.sender] = 100000000000000000;
        totalSupply = 100000000000000000;
        name = "JAVCoin";
        decimals = 8;
        symbol = "JAV";
        version = "H1.0";
        unitsOneEthCanBuy = 10000;
        fundsWallet = msg.sender;
    }
    
    function() payable {
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        
        if (balances[fundsWallet] < amount) {
            return;
        }
        
        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        
        Transfer(fundsWallet, msg.sender, amount);
        
        fundsWallet.transfer(msg.value);
    }
    
    function approveAndCall(address spender, uint256 tokens, bytes data) returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        
        if(!spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, tokens, this, data)) {
            throw;
        }
        return true;
    }
}
```