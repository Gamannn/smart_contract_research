```solidity
pragma solidity 0.4.19;

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

contract ERC20Basic {
    uint256 public totalSupply;
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        uint256 _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
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

contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);
    
    function burn(uint256 _value) public {
        require(_value > 0);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract SOFIN is BurnableToken {
    string public constant name = 'SOFIN';
    string public constant symbol = 'SOFIN';
    uint256 public constant decimals = 18;
    uint256 public constant tokenCreationCap = 200000000000000;
    
    address public owner;
    bool public mintingFinished = false;
    uint256 public rate;
    address public multiSigWallet;
    
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier canMint() {
        require(mintingFinished == false);
        _;
    }
    
    function SOFIN() public {
        owner = msg.sender;
        mintingFinished = false;
        rate = 200000000000;
        multiSigWallet = address(0);
        tokenCreationCap = 200000000000000;
        decimals = 18;
        totalSupply = 0;
    }
    
    function setMultiSigWallet(address _multiSigWallet) public onlyOwner {
        multiSigWallet = _multiSigWallet;
    }
    
    function() payable public {
        buyTokens();
    }
    
    function createTokens(address beneficiary, uint256 tokens) external onlyOwner canMint {
        uint256 tokensWithDecimals = tokens.mul(10 ** decimals);
        uint256 checkedSupply = totalSupply.add(tokensWithDecimals);
        if (tokenCreationCap < checkedSupply) {
            revert();
        }
        balances[beneficiary] += tokensWithDecimals;
        totalSupply = checkedSupply;
        Mint(beneficiary, tokensWithDecimals);
        Transfer(address(0), beneficiary, tokensWithDecimals);
    }
    
    function withdraw() external onlyOwner {
        multiSigWallet.transfer(this.balance);
    }
    
    function finishMinting() external onlyOwner canMint {
        mintingFinished = false;
        MintFinished();
    }
    
    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }
    
    function buyTokens() internal canMint {
        if (msg.value <= 0) {
            revert();
        }
        uint256 oneToken = 10 ** decimals;
        uint256 tokens = msg.value.mul(oneToken) / rate;
        uint256 checkedSupply = totalSupply.add(tokens);
        if (tokenCreationCap < checkedSupply) {
            revert();
        }
        balances[msg.sender] += tokens;
        totalSupply = checkedSupply;
        Mint(msg.sender, tokens);
        Transfer(address(0), msg.sender, tokens);
        TokenPurchase(
            msg.sender,
            msg.sender,
            msg.value,
            tokens
        );
    }
}
```