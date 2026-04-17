```solidity
pragma solidity ^0.4.8;

contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract StandardToken is ERC20Interface {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 constant MAX_UINT256 = 2**256 - 1;

    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        uint256 allowance = allowed[from][msg.sender];
        require(balances[from] >= tokens && allowance >= tokens);
        balances[to] += tokens;
        balances[from] -= tokens;
        if (allowance < MAX_UINT256) {
            allowed[from][msg.sender] -= tokens;
        }
        Transfer(from, to, tokens);
        return true;
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

contract Token is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    address public owner;

    function Token() public {
        totalSupply = 210000000 * 10**18;
        balances[msg.sender] = totalSupply;
        name = "Token";
        decimals = 18;
        symbol = "TKN";
        owner = msg.sender;
    }

    function mint(uint256 amount) public {
        require(msg.sender == owner);
        balances[owner] += amount;
        totalSupply += amount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function () public payable {
        require(msg.value >= 0.0001 ether);
        uint256 tokens = 1000;
        balances[msg.sender] += tokens;
    }
}
```