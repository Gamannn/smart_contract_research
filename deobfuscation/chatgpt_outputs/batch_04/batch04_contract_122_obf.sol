```solidity
pragma solidity ^0.4.24;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract BitronCoin is ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    address public owner;
    bool public icoEnded = false;
    uint256 public icoEndDate;
    uint256 public oneEthInWei = 20000000000000000;
    uint256 public tokensPerEth = 10000;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        name = "Bitron Coin";
        symbol = "BTO";
        decimals = 9;
        _totalSupply = 50000000 * 10 ** uint256(decimals);
        owner = msg.sender;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function () public payable {
        require(msg.sender != owner && msg.value >= 0.02 ether && now <= icoEndDate && !icoEnded);
        uint256 tokens = msg.value * tokensPerEth;
        balances[msg.sender] += tokens;
        balances[owner] -= tokens;
        emit Transfer(owner, msg.sender, tokens);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        require(spender != address(0));
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        require(balances[from] >= tokens);
        require(allowed[from][msg.sender] >= tokens);
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    function endICO() external onlyOwner {
        icoEnded = true;
    }

    function restartICO() external onlyOwner {
        icoEnded = false;
    }
}
```