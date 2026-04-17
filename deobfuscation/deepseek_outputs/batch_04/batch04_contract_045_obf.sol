```solidity
pragma solidity ^0.4.8;

contract ERC20Interface {
    uint256 public totalSupply;
    address public target;
    uint256 public totalCount;
    
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20Token is ERC20Interface {
    uint256 constant MAX_UINT256 = 2**256 - 1;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowanceAmount = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowanceAmount >= _value);
        
        balances[_to] += _value;
        balances[_from] -= _value;
        
        if (allowanceAmount < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        
        Transfer(_from, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Ae1Token is ERC20Token {
    string public name;
    uint8 public decimals;
    string public symbol;
    
    address public owner;
    uint256 public initialSupply;
    
    constructor() public {
        name = "Ae1Token";
        decimals = 18;
        symbol = "ae1";
        totalSupply = 10000 * (10**22);
        initialSupply = totalSupply;
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        
        if (msg.sender != target) {
            owner.transfer(address(this).balance);
        }
    }
    
    modifier onlyIfSupplyRemaining() {
        if (totalSupply > 0) {
            _;
        } else {
            revert();
        }
    }
    
    function() public payable onlyIfSupplyRemaining {
        assert(msg.value >= 0.0001 ether);
        uint256 tokensToMint = 1000 * msg.value;
        
        balances[msg.sender] += tokensToMint;
        balances[owner] -= tokensToMint;
        totalSupply -= tokensToMint;
        
        owner.transfer(msg.value);
    }
    
    uint256[] public _integer_constant = [1000, 1, 18, 100000000000000, 10, 0, 21000, 22, 2, 10000, 5555555555555, 256];
    string[] public _string_constant = ["ae1", "Ae1Token", "H0.1"];
    bool[] public _bool_constant = [true];
}
```