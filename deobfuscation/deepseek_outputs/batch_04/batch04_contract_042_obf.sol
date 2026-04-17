```solidity
pragma solidity ^0.4.24;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract ERC20Token is ERC20Interface {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 public totalSupply;
    
    function transfer(address to, uint256 tokens) public returns (bool success) {
        if (balances[msg.sender] >= tokens && tokens > 0) {
            balances[msg.sender] -= tokens;
            balances[to] += tokens;
            Transfer(msg.sender, to, tokens);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
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
    
    string public name;
    uint8 public decimals;
    
    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        
        if(!spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, tokens, this, data)) {
            revert();
        }
        return true;
    }
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TokenRecover is Ownable {
    constructor() public {}
    
    function recoverTokens(ERC20Token token, address to, uint256 amount) public onlyOwner {
        require(token != address(0));
        require(to != address(0));
        require(to != address(this));
        assert(token.transfer(to, amount));
    }
}

contract TokenSale is TokenRecover {
    uint256 public price = 1;
    ERC20Token public token;
    
    constructor(uint256 initialPrice, ERC20Token tokenAddress) public {
        price = initialPrice;
        token = tokenAddress;
    }
    
    function setPrice(uint256 newPrice) public onlyOwner {
        require(newPrice > 0, 'invalid price');
        price = newPrice;
    }
    
    function() public payable {
        require(msg.value > 0, 'no eth received');
        buyTokens(msg.sender);
    }
    
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function buyTokens(address beneficiary) public payable {
        uint256 tokenAmount = safeMultiply(msg.value, price);
        token.transfer(beneficiary, tokenAmount);
    }
    
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}
```