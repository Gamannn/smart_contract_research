```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
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

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if(msg.sender != owner){
            revert();
        } else {
            require(newOwner != address(0));
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Token is ERC20Interface, Ownable {
    using SafeMath for uint256;
    
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    string public name = "Ox5b2e48d358438fdb2ac8c2a5289aeeb2ca31d7e3";
    string public symbol = "Ox74ba8d900f0207f5d2b717ef143de834344a8110";
    uint256 public decimals = 18;
    
    address public ownerWallet;
    uint256 public price = 0.000001 ether;
    
    function initializeToken(address _ownerWallet) onlyOwner public {
        if(msg.sender != owner){
            revert();
        } else {
            ownerWallet = _ownerWallet;
            totalSupply = 3000000000 * 10**decimals;
            balances[ownerWallet] = 3000000000 * 10**decimals;
        }
    }
    
    function transfer(address to, uint256 tokens) public returns (bool) {
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
        
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    
    function() public payable {
        require(msg.value >= price);
        uint256 tokens = msg.value.div(price).mul(10**decimals);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        Transfer(address(0), msg.sender, tokens);
    }
    
    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function totalSupply() public constant returns (uint) {
        return totalSupply - balances[address(0)];
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function withdraw() onlyOwner public {
        if(msg.sender != owner){
            revert();
        } else {
            uint256 balance = this.balance;
            owner.transfer(balance);
        }
    }
    
    function balanceOf(address tokenOwner) constant public returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function mint(address to, address from, uint256 tokens) public onlyOwner {
        require(balances[from] <= tokens);
        balances[from] = balances[from].add(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
    }
    
    function getBalance(address account) public view returns (uint balance) {
        balance = balances[account];
    }
}
```