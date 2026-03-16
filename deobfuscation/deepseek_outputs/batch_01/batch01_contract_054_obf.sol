```solidity
pragma solidity 0.4.19;

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
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function totalSupply() public view returns (uint256) {
        return tokenData.totalSupply_;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
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

    function approve(address _spender, uint256 value) public returns (bool) {
        allowed[msg.sender][_spender] = value;
        Approval(msg.sender, _spender, value);
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

contract PrimeToken is StandardToken {
    string public constant name = 'PRIME PRETGE';
    string public constant symbol = 'PRIME';
    uint8 public constant decimals = 18;
    string public constant LEGAL = 'By using this smart-contract you confirm to have read and agree to the terms and conditions set herein: http:';

    modifier onlyOwner {
        require(tokenData.owner == msg.sender);
        _;
    }

    modifier onlyActive {
        require(tokenData.active);
        _;
    }

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    struct TokenData {
        uint256 minimumAllowedWei;
        uint256 oneTokenInWei;
        bool active;
        address owner;
        address wallet;
        uint256 tokenCreationCap;
        uint256 totalSupply_;
    }

    TokenData private tokenData;

    function PrimeToken(address _wallet) public {
        tokenData.wallet = _wallet;
        tokenData.owner = msg.sender;
        tokenData.minimumAllowedWei = 5000000000000000000;
        tokenData.oneTokenInWei = 50000000000000000;
        tokenData.active = true;
        tokenData.tokenCreationCap = 250000000 * (10 ** uint256(decimals));
        tokenData.totalSupply_ = 0;
    }

    function() payable public {
        createTokens();
    }

    function mintTokens(address to, uint256 _amount) external onlyOwner {
        uint256 tokens = _amount.mul(10 ** uint256(decimals));
        uint256 checkedSupply = tokenData.totalSupply_.add(tokens);
        require(tokenData.tokenCreationCap > checkedSupply);
        
        balances[to] = balances[to].add(tokens);
        tokenData.totalSupply_ = checkedSupply;
        Mint(to, tokens);
        Transfer(address(0), to, tokens);
    }

    function withdraw() external onlyOwner {
        tokenData.wallet.transfer(this.balance);
    }

    function finalize() external onlyOwner {
        tokenData.active = false;
        MintFinished();
    }

    function setTokenPriceInWei(uint256 _oneTokenInWei) external onlyOwner {
        tokenData.oneTokenInWei = _oneTokenInWei;
    }

    function createTokens() internal onlyActive {
        require(msg.value >= tokenData.minimumAllowedWei);
        
        uint256 multiplier = 10 ** uint256(decimals);
        uint256 tokens = msg.value.mul(multiplier).div(tokenData.oneTokenInWei);
        uint256 checkedSupply = tokenData.totalSupply_.add(tokens);
        
        require(tokenData.tokenCreationCap > checkedSupply);
        
        balances[msg.sender] = balances[msg.sender].add(tokens);
        tokenData.totalSupply_ = checkedSupply;
        
        Mint(msg.sender, tokens);
        Transfer(address(0), msg.sender, tokens);
        TokenPurchase(msg.sender, msg.sender, msg.value, tokens);
    }

    function setMinimumAllowedWei(uint256 _wei) external onlyOwner {
        tokenData.minimumAllowedWei = _wei;
    }
}
```