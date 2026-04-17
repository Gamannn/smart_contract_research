```solidity
pragma solidity^0.4.21;

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
        return a / b;
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

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply_;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function burn(uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_from, _value);
        return true;
    }
}

contract Token is StandardToken, Ownable {
    address public founderAddress;
    bool public unlocked;
    mapping(address => bool) public frozenAccounts;

    event UnLockAllTokens(bool unlocked);
    event FrozenFunds(address target, bool frozen);

    constructor() public {
        founderAddress = msg.sender;
        balances[founderAddress] = totalSupply_;
        emit Transfer(address(0), founderAddress, totalSupply_);
    }

    function transfer(address _to, uint256 _value) public {
        require(!frozenAccounts[msg.sender] || unlocked);
        super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!frozenAccounts[_from] || unlocked);
        return super.transferFrom(_from, _to, _value);
    }

    function unlockAllTokens(bool _unlocked) public onlyOwner {
        unlocked = _unlocked;
        emit UnLockAllTokens(_unlocked);
    }

    function freezeAccount(address _target, bool _freeze) public onlyOwner {
        frozenAccounts[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;

    Token public token;
    address public wallet;
    uint256 public rate;
    uint256 public limitTokenForSale;

    event ChangeRate(address indexed owner, uint256 newRate);
    event GetEther(uint256 amount);
    event FinishCrowdSale();

    constructor() public {
        rate = 15000;
        wallet = msg.sender;
        limitTokenForSale = 9270000000000000000;
        token = Token(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d);
    }

    function () public payable {
        require(msg.value > 0);
        uint256 tokens = rate.mul(msg.value);
        require(tokens <= limitTokenForSale);

        token.transfer(msg.sender, tokens);
        wallet.transfer(msg.value);
    }

    function changeRate(uint256 newRate) public onlyOwner {
        require(newRate > 0);
        rate = newRate;
        emit ChangeRate(msg.sender, newRate);
    }

    function finish() public onlyOwner {
        uint256 remainingTokens = token.balanceOf(this);
        token.transfer(owner, remainingTokens);
        emit FinishCrowdSale();
    }

    function withdrawEther(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance);
        wallet.transfer(amount);
        emit GetEther(amount);
    }
}
```