```solidity
pragma solidity ^0.4.11;

contract ERC20Basic {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract KPRCoin is ERC20 {
    using SafeMath for uint256;
    
    string public constant name = "KPR Coin";
    string public constant symbol = "KPR";
    uint8 public constant decimals = 18;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    uint256 public totalSupply;
    uint256 public buyableToken;
    address public owner;
    
    uint256 public phase1StartTime = 1517443200;
    uint256 public phase1EndTime = 1519257600;
    uint256 public phase2StartTime = 1519862400;
    uint256 public phase2EndTime = 1521676800;
    uint256 public phase3StartTime = 1522540800;
    uint256 public phase3EndTime = 1524355200;
    
    uint256 public RATE = 0;
    
    function KPRCoin() {
        owner = msg.sender;
        totalSupply = 90000000 * 10 ** uint256(decimals);
        balances[owner] = totalSupply;
        buyableToken = totalSupply;
    }
    
    function buyTokens() payable {
        require(msg.value > 0);
        require(now > phase1StartTime && now < phase3EndTime);
        
        uint256 tokens;
        if (now > phase1StartTime && now < phase1EndTime) {
            RATE = 3000;
            tokens = msg.value.mul(RATE);
        } else if (now > phase2StartTime && now < phase2EndTime) {
            RATE = 2000;
            tokens = msg.value.mul(RATE);
        } else if (now > phase3StartTime && now < phase3EndTime) {
            RATE = 1000;
            tokens = msg.value.mul(RATE);
        }
        
        require(tokens < buyableToken);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        buyableToken = buyableToken.sub(tokens);
        owner.transfer(msg.value);
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(
            allowed[_from][msg.sender] >= _value &&
            balances[_from] >= _value &&
            _value > 0
        );
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```