```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256);
    function allowance(address tokenOwner, address spender) external view returns (uint256);
    function transfer(address to, uint256 tokens) external returns (bool);
    function approve(address spender, uint256 tokens) external returns (bool);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool);
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 tokens
    );
}

contract ERC20Token is ERC20Interface {
    using SafeMath for uint256;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    uint256 private totalSupply_;
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowed[tokenOwner][spender];
    }
    
    function transfer(address to, uint256 tokens) public returns (bool) {
        require(tokens <= balances[msg.sender]);
        require(to != address(0));
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
        require(to != address(0));
        
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        
        emit Transfer(from, to, tokens);
        return true;
    }
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        transferOwnershipInternal(newOwner);
    }
    
    function transferOwnershipInternal(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract OLE is ERC20Token, Ownable {
    event tokenComprado(address comprador);
    
    string public constant name = "OLE";
    string public constant symbol = "OLE";
    uint8 public constant decimals = 18;
    uint256 public tokenPrice = 100000000000000;
    uint256 public constant INITIAL_SUPPLY = 150000000 * (10 ** uint256(decimals));
    
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
    
    function() public payable {
        emit tokenComprado(msg.sender);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function setTokenPrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }
    
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    function buyTokens(uint256 amount) public payable {
        require(amount > 0);
        require(msg.value == (amount * tokenPrice));
        
        uint256 tokens = amount * (10 ** uint256(decimals));
        
        balances[owner] = balances[owner].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        
        address(this).transfer(msg.value);
        emit Transfer(owner, msg.sender, tokens);
    }
}
```