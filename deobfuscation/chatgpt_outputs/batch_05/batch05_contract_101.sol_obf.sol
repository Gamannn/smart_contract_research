pragma solidity ^0.4.15;

contract ERC20Interface {
    function totalSupply() constant returns (uint256);
    function balanceOf(address tokenOwner) constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) returns (bool success);
    function approve(address spender, uint256 tokens) returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) returns (bool success);
    function allowance(address tokenOwner, address spender) constant returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract PotatoToken is ERC20Interface {
    string public constant name = "POTATO";
    string public constant symbol = "POT";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    address public owner;
    uint256 public deadline;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function PotatoToken() {
        owner = msg.sender;
        totalSupply = 1000000 * 10**uint256(decimals);
        balances[owner] = totalSupply;
        deadline = now + 14 * 1 days;
    }

    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address tokenOwner) constant returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens) returns (bool success) {
        require(balances[msg.sender] >= tokens && tokens > 0 && balances[to] + tokens > balances[to]);
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) returns (bool success) {
        require(balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens > 0 && balances[to] + tokens > balances[to]);
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    function extendDeadline() onlyOwner {
        deadline = now + 14 * 1 days;
    }

    function () payable {
        require(now < deadline);
        uint256 tokens = msg.value / 1000000000000000;
        totalSupply += tokens;
        balances[msg.sender] += tokens;
    }
}