```solidity
pragma solidity ^0.4.26;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256);
    function transfer(address to, uint256 tokens) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    function allowance(address tokenOwner, address spender) public view returns (uint256);
    function approve(address spender, uint256 tokens) public returns (bool);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract PostboyToken is ERC20Interface {
    using SafeMath for uint256;
    
    struct Account {
        uint256 balance;
        uint256 lastDividendPoints;
    }
    
    string public constant name = "PostboyToken";
    string public constant symbol = "PBY";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    uint256 public totalDividends;
    
    mapping(address => Account) private accounts;
    mapping(address => mapping(address => uint256)) private allowances;
    
    address public owner;
    address public dividendDistributor;
    
    constructor() public {
        totalSupply = 100000 * 10**uint256(decimals);
        accounts[msg.sender].balance = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    function transfer(address to, uint256 tokens) public returns (bool) {
        _transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(tokens <= allowances[from][msg.sender]);
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(tokens);
        _transfer(from, to, tokens);
        return true;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return accounts[tokenOwner].balance;
    }
    
    function approve(address spender, uint256 tokens) public returns (bool) {
        allowances[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowances[tokenOwner][spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowances[msg.sender][spender] = allowances[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        if (subtractedValue > currentAllowance) {
            allowances[msg.sender][spender] = 0;
        } else {
            allowances[msg.sender][spender] = currentAllowance.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }
    
    function dividendsOf(address account) public view returns (uint256) {
        uint256 pointsDiff = totalDividends.sub(accounts[account].lastDividendPoints);
        uint256 dividend = accounts[account].balance.mul(pointsDiff);
        return dividend.div(totalSupply);
    }
    
    function claimDividends() public {
        uint256 dividend = dividendsOf(msg.sender);
        if (dividend > 0) {
            accounts[msg.sender].lastDividendPoints = totalDividends;
            msg.sender.transfer(dividend);
        }
    }
    
    function _transfer(address from, address to, uint256 tokens) internal {
        require(to != address(0));
        require(tokens <= accounts[from].balance);
        require(accounts[to].balance.add(tokens) >= accounts[to].balance);
        
        uint256 fromDividend = dividendsOf(from);
        uint256 toDividend = dividendsOf(to);
        require(fromDividend <= 0 && toDividend <= 0);
        
        accounts[from].balance = accounts[from].balance.sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);
        accounts[to].lastDividendPoints = accounts[from].lastDividendPoints;
        
        emit Transfer(from, to, tokens);
    }
    
    function setDividendDistributor(address newDistributor) public returns (bool) {
        require(msg.sender == owner);
        dividendDistributor = newDistributor;
        return true;
    }
    
    function addDividends() public payable {
        require(msg.sender == dividendDistributor);
        totalDividends = totalDividends.add(msg.value);
    }
    
    function() external payable {
        require(false);
    }
}

contract PostboyTokenMiddleware {
    address public tokenAddress;
    address public dividendDistributor;
    address public adminAddress;
    
    PostboyToken public token;
    
    modifier onlyAuthorized() {
        require(msg.sender == tokenAddress || msg.sender == dividendDistributor || msg.sender == adminAddress);
        _;
    }
    
    constructor(address _tokenAddress, address _dividendDistributor, address _adminAddress) public {
        tokenAddress = _tokenAddress;
        dividendDistributor = _dividendDistributor;
        adminAddress = _adminAddress;
        token = PostboyToken(_tokenAddress);
    }
    
    function transferDividends() public onlyAuthorized {
        token.addDividends.value(address(this).balance)();
    }
    
    function() external payable {
    }
}
```