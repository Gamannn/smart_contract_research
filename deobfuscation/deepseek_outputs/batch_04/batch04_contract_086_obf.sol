```solidity
pragma solidity ^0.4.21;

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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TokenERC20 is Ownable {
    using SafeMath for uint256;
    
    string public constant name = "IOGENESIS";
    string public constant symbol = "IOG";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(uint256 initialSupply) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(!frozenAccount[msg.sender]);
        require(value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        require(!frozenAccount[from]);
        
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
    
    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function _balanceOf(address _owner) internal constant returns(uint256) {
        return balances[_owner];
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balanceOf(_owner);
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function() payable public {
        if (balances[airdropAddress] >= startBalance && startBalance == 1 ether && !airdrops[msg.sender]) {
            require(startBalance == 1 ether);
            require(balances[airdropAddress] >= startBalance);
            
            balances[airdropAddress] = balances[airdropAddress].sub(startBalance);
            balances[msg.sender] = balances[msg.sender].add(startBalance);
            airdrops[msg.sender] = true;
            emit Transfer(airdropAddress, msg.sender, startBalance);
        }
    }
    
    function withdraw(uint amount) payable public onlyOwner {
        owner.transfer(amount);
    }
    
    uint256 public startBalance = 1 ether;
    address public airdropAddress = 0xBfB92c13455c4ab69A2619614164c45Cb4BEC09C;
    mapping(address => bool) public airdrops;
}
```