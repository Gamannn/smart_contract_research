```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
    
    function min(uint a, uint b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract WrappedEther {
    using SafeMath for uint256;
    
    string public name = "Wrapped Ether";
    string public constant symbol = "WETH";
    uint8 public constant decimals = 18;
    
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal totalSupply_;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event StateChanged(bool status, string message);
    
    function deposit() public payable {
        require(msg.value > 0);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        totalSupply_ = totalSupply_.add(msg.value);
        emit Transfer(address(0), msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) public {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);
        msg.sender.transfer(amount);
        emit Transfer(msg.sender, address(0), amount);
    }
    
    function balanceOf(address owner) public constant returns (uint256 balance) {
        return balances[owner];
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        if (balances[msg.sender] >= value && 
            value > 0 && 
            balances[to].add(value) > balances[to]) {
            balances[msg.sender] = balances[msg.sender].sub(value);
            balances[to] = balances[to].add(value);
            emit Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if (balances[from] >= value && 
            allowed[from][msg.sender] >= value && 
            value > 0 && 
            balances[to].add(value) > balances[to]) {
            balances[from] = balances[from].sub(value);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
            balances[to] = balances[to].add(value);
            emit Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
    
    function totalSupply() public constant returns (uint256) {
        return totalSupply_;
    }
}
```