```solidity
pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
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

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Owned {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;
    address public newOwner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract AllStocksToken is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public constant symbol = "AST";
    string public constant name = "AllStocks Token";
    uint8 public constant decimals = 18;

    uint256 _totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) contributions;

    function AllStocksToken() public {
        _totalSupply = 25 * (10**6) * 10**uint256(decimals);
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
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
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
}

contract AllStocksCrowdsale is AllStocksToken {
    using SafeMath for uint256;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public rate;
    uint256 public cap;
    bool public isFinalized = false;

    event LogRefund(address indexed investor, uint256 amount);
    event CreateAllstocksToken(address indexed investor, uint256 amount);

    function AllStocksCrowdsale() public {
        rate = 625;
        cap = 50 * (10**6) * 10**uint256(decimals);
        startTime = 0;
        endTime = 0;
    }

    function setCrowdsale(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(!isFinalized);
        require(_startTime > 0);
        require(_endTime > _startTime);
        startTime = _startTime;
        endTime = _endTime;
    }

    function () public payable {
        buyTokens(msg.value);
    }

    function buyTokens(uint256 weiAmount) internal {
        require(!isFinalized);
        require(now >= startTime && now < endTime);
        require(weiAmount > 0);

        uint256 tokens = weiAmount.mul(rate);
        uint256 newTotalSupply = _totalSupply.add(tokens);
        require(newTotalSupply <= cap);

        _totalSupply = newTotalSupply;
        balances[msg.sender] = balances[msg.sender].add(tokens);
        contributions[msg.sender] = contributions[msg.sender].add(weiAmount);

        CreateAllstocksToken(msg.sender, tokens);
        Transfer(address(0), owner, _totalSupply);
    }

    function finalize() external onlyOwner {
        require(!isFinalized);
        require(now >= endTime || _totalSupply >= cap);
        isFinalized = true;
    }

    function refund() external {
        require(!isFinalized);
        require(now > endTime);
        require(_totalSupply < cap);
        require(msg.sender != owner);

        uint256 tokens = balances[msg.sender];
        uint256 contribution = contributions[msg.sender];
        require(tokens > 0);
        require(contribution > 0);

        balances[msg.sender] = 0;
        contributions[msg.sender] = 0;
        _totalSupply = _totalSupply.sub(tokens);

        uint256 refundAmount = tokens.div(rate);
        require(contribution <= refundAmount);

        msg.sender.transfer(contribution);
        LogRefund(msg.sender, contribution);
    }
}
```