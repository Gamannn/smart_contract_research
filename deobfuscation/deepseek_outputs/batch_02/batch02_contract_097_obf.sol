```solidity
pragma solidity ^0.4.24;

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

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract MRNToken is StandardToken {
    string public constant name = "MRN";
    string public constant symbol = "MRN";
    uint8 public constant decimals = 18;
    
    address public devWallet;
    uint256 public maxSupply;
    uint256 public MRNToEthWei;
    
    struct TokenConfig {
        address devWallet;
        uint256 maxSupply;
        uint256 MRNToEthWei;
        uint256 totalSupply;
        uint8 decimals;
        string symbol;
        string name;
        uint256 initialSupply;
    }
    
    TokenConfig config = TokenConfig(address(0), 0, 0, 0, 0, "", "", 0);
    
    function MRNToken() public {
        config.name = name;
        config.symbol = symbol;
        config.decimals = decimals;
        config.maxSupply = 20000000 * (10 ** uint256(decimals));
        config.initialSupply = 1000000000 * (10 ** uint256(decimals));
        config.MRNToEthWei = 10;
        config.devWallet = msg.sender;
        
        totalSupply = config.initialSupply;
        balances[msg.sender] = config.initialSupply;
        Transfer(address(0), msg.sender, config.initialSupply);
    }
    
    function() public payable {
        require(msg.value > 0);
        uint256 tokens = msg.value * config.MRNToEthWei;
        
        if (balances[config.devWallet] < tokens) {
            return;
        }
        
        balances[config.devWallet] = balances[config.devWallet].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        Transfer(config.devWallet, msg.sender, tokens);
        config.devWallet.transfer(msg.value);
    }
    
    uint256[] public _integer_constant = [20000000, 0, 1000000000, 10, 18];
    bool[] public _bool_constant = [true];
    string[] public _string_constant = ["MRN", "MRN"];
}
```