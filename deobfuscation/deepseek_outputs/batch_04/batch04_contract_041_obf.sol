```solidity
pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

interface ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Owned {
    address public owner;
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    function Owned() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract ERC20Token is ERC20, Owned {
    using SafeMath for uint256;
    
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    
    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        require(balances[from] >= tokens);
        require(allowed[from][msg.sender] >= tokens);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    
    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
}

contract CrowdsaleToken is ERC20Token {
    function CrowdsaleToken() payable ERC20Token() public {
        totalSupply = 1000000000 * 10**18;
        balances[owner] = totalSupply.sub(balances[this]);
        Transfer(this, owner, balances[owner]);
    }
    
    function () payable public {
        require(balances[this] > 0);
        uint256 tokenPrice = 200000 * 10**18;
        uint256 tokens = tokenPrice.mul(msg.value).div(10**18);
        
        if (tokens > balances[this]) {
            tokens = balances[this];
            uint256 refund = tokens.mul(10**18).div(tokenPrice);
            msg.sender.transfer(msg.value.sub(refund));
        }
        
        require(tokens > 0);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[this] = balances[this].sub(tokens);
        Transfer(this, msg.sender, tokens);
    }
}

contract PerfectCoin is CrowdsaleToken {
    using SafeMath for uint256;
    
    string public name = 'PerfectCoin';
    string public symbol = 'PC';
    uint8 public decimals = 18;
    
    function PerfectCoin() payable CrowdsaleToken() public {}
    
    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function withdraw() onlyOwner public {
        owner.transfer(this.balance);
    }
    
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
}
```