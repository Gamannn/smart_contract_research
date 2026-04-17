```solidity
pragma solidity ^0.4.15;

contract ERC20 {
    function totalSupply() constant returns (uint256);
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PotatoToken is ERC20 {
    string public constant name = "POTATO";
    string public constant symbol = "POT";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    uint256 public deadline;
    address public owner;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function PotatoToken() {
        owner = msg.sender;
        balances[owner] = totalSupply;
        deadline = now + 14 * 1 days;
    }
    
    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }
    
    function transfer(address to, uint256 value) returns (bool success) {
        if (balances[msg.sender] >= value && 
            value > 0 && 
            balances[to] + value > balances[to]) {
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        if (balances[from] >= value && 
            allowed[from][msg.sender] >= value && 
            value > 0 && 
            balances[to] + value > balances[to]) {
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            balances[to] += value;
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function approve(address spender, uint256 value) returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
    
    function withdraw() onlyOwner {
        require(msg.sender == owner);
        this.transfer(owner, this.balanceOf(this));
    }
    
    function extendDeadline() onlyOwner {
        require(msg.sender == owner);
        deadline = now + 14 * 1 days;
    }
    
    function kill() onlyOwner {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
    
    function () payable {
        require(now < deadline);
        uint256 tokenReward = msg.value / 1000000000000000;
        totalSupply += tokenReward;
        balances[msg.sender] += tokenReward;
    }
}
```