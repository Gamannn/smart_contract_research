```solidity
pragma solidity ^0.4.18;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    address public owner;
    
    function Ownable() public {
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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
    
    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract QIUToken is StandardToken, Ownable {
    string public name = 'QIUToken';
    string public symbol = 'QIU';
    
    function() public payable {
    }
    
    function QIUToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[owner] = INITIAL_SUPPLY / 10;
        balances[this] = INITIAL_SUPPLY - balances[owner];
    }
    
    function getOwner() public view returns (address) {
        return owner;
    }
    
    function transferFromOwner(address from, address to, uint256 value) public returns (bool) {
        require(tx.origin == owner);
        require(to != address(0));
        require(value <= balances[from]);
        
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(from, to, value);
        return true;
    }
    
    function transferFromOrigin(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[tx.origin]);
        
        balances[tx.origin] = balances[tx.origin].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(tx.origin, to, value);
        return true;
    }
    
    event ExchangeForETH(address from, address to, uint qiuAmount, uint ethAmount);
    
    function sellQIU(uint qiuAmount) public returns (bool) {
        uint ethAmount = qiuAmount * 1 ether / EXCHANGE_RATE;
        require(this.balanceOf(this) >= ethAmount);
        
        balances[this] = balances[this].add(qiuAmount);
        balances[msg.sender] = balances[msg.sender].sub(qiuAmount);
        msg.sender.transfer(ethAmount);
        ExchangeForETH(this, msg.sender, qiuAmount, ethAmount);
        return true;
    }
    
    event ExchangeForQIU(address from, address to, uint qiuAmount, uint ethAmount);
    
    function buyQIU() payable public returns (bool) {
        uint qiuAmount = msg.value * EXCHANGE_RATE / 1 ether;
        require(qiuAmount <= balances[this]);
        
        balances[this] = balances[this].sub(qiuAmount);
        balances[msg.sender] = balances[msg.sender].add(qiuAmount);
        ExchangeForQIU(this, msg.sender, qiuAmount, msg.value);
        return true;
    }
    
    function getContractBalance() public view returns (uint) {
        return this.balanceOf(this);
    }
    
    uint256 private constant EXCHANGE_RATE = 10000;
    uint256 private constant INITIAL_SUPPLY = 5000000000;
    uint256 private totalSupply_;
}
```