```solidity
pragma solidity 0.4.19;

contract ERC20Interface {
    function totalSupply() constant public returns (uint256);
    function balanceOf(address tokenOwner) constant public returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) constant public returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract Token is ERC20Interface, SafeMath {
    string public name = "TokenName";
    string public symbol = "TKN";
    uint8 public decimals = 18;
    uint256 public _totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    function Token() public {
        _totalSupply = 50000000 * 10**uint256(decimals);
        balances[msg.sender] = _totalSupply;
        Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() constant public returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) constant public returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) constant public returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
}
```