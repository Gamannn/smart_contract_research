```solidity
pragma solidity ^0.4.21;

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
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
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
    event Burn(address indexed from, uint256 value);
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
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to].add(_value) > balances[_to]);
        
        uint256 previousBalances = balances[_from].add(balances[_to]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balances[_from].add(balances[_to]) == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
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
    
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
}

contract FreezableToken is StandardToken, Ownable {
    address public founderAddress;
    bool public unlockAllTokens;
    mapping(address => bool) public frozenAccount;
    
    event UnLockAllTokens(bool unlock);
    event FrozenFunds(address target, bool frozen);
    
    constructor() public {
        founderAddress = msg.sender;
        balances[founderAddress] = totalSupply_;
        emit Transfer(address(0), founderAddress, totalSupply_);
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to].add(_value) >= balances[_to]);
        require(!frozenAccount[_from] || unlockAllTokens);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }
    
    function setUnlockAllTokens(bool _unlock) public onlyOwner {
        unlockAllTokens = _unlock;
        emit UnLockAllTokens(_unlock);
    }
    
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;
    
    FreezableToken public token;
    address public wallet;
    uint256 public currentRate;
    uint256 public limitTokenForSale;
    
    event ChangeRate(address indexed changer, uint256 newRate);
    event FinishCrowdSale();
    event GetEther(uint256 amount);
    
    constructor() public {
        currentRate = 15000;
        wallet = msg.sender;
        limitTokenForSale = 2338644692700000000000000000;
        token = FreezableToken(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d);
    }
    
    function() public payable {
        require(msg.value > 0);
        uint256 tokenAmount = currentRate.mul(msg.value);
        require(tokenAmount <= token.balanceOf(this));
        
        uint256 tokenToSend = currentRate.mul(msg.value);
        token.transfer(msg.sender, tokenToSend);
    }
    
    function setRate(uint256 _newRate) public onlyOwner {
        require(_newRate > 0);
        currentRate = _newRate;
        emit ChangeRate(msg.sender, _newRate);
    }
    
    function getTokenBalance() view public returns (uint256) {
        return token.balanceOf(this);
    }
    
    function finish() public onlyOwner {
        uint256 remainingTokens = getTokenBalance();
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