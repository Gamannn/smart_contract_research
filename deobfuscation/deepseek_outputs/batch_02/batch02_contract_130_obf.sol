```solidity
pragma solidity ^0.4.13;

contract ReentrancyGuard {
    uint256 private _guardCounter;
    
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
    
    constructor() public {
        _guardCounter = 1;
    }
}

contract Ownable {
    address public owner;
    address public pendingOwner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }
    
    function claimOwnership() public {
        require(msg.sender == pendingOwner);
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
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
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract Crowdsale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    
    enum State { INIT, ICO, CLOSED, PAUSE }
    
    uint256 public constant DECIMALS = 18;
    uint256 public constant MAX_SUPPLY = 3400000000 * (10 ** DECIMALS);
    uint256 public constant WEI_DECIMALS = 10 ** 18;
    
    StandardToken public token;
    address public beneficiary;
    uint256 public currentPrice;
    uint256 public totalFunds;
    uint256 public countMembers;
    State public currentState;
    
    mapping(address => bool) public whitelist;
    
    event Transfer(address indexed to, uint256 value);
    
    modifier inState(State state) {
        require(currentState == state);
        _;
    }
    
    modifier onlyICO() {
        require(currentState == State.ICO);
        _;
    }
    
    modifier notClosed() {
        require(currentState != State.CLOSED);
        _;
    }
    
    constructor(address _beneficiary) public {
        beneficiary = _beneficiary;
        currentState = State.INIT;
        currentPrice = WEI_DECIMALS / 166;
    }
    
    function() public payable onlyICO {
        buyTokens();
    }
    
    function setToken(address _token) public onlyOwner inState(State.INIT) {
        require(_token != address(0));
        token = StandardToken(_token);
    }
    
    function setCurrentPrice(uint256 _price) public onlyOwner notClosed {
        currentPrice = _price;
    }
    
    function setPriceByWei(uint256 _wei) public onlyOwner notClosed {
        currentPrice = WEI_DECIMALS / _wei;
    }
    
    function setState(State _state) public onlyOwner {
        require(currentState != State.CLOSED);
        require(
            (currentState == State.INIT && _state == State.ICO) ||
            (currentState == State.ICO && _state == State.CLOSED) ||
            (currentState == State.ICO && _state == State.PAUSE) ||
            (currentState == State.PAUSE && _state == State.ICO)
        );
        
        if (_state == State.CLOSED) {
            finalize();
        }
        currentState = _state;
    }
    
    function withdraw(uint256 _amount) public onlyOwner nonReentrant {
        require(_amount > 0 && _amount <= address(this).balance);
        beneficiary.transfer(_amount);
    }
    
    function buyTokensFor(address _to, uint256 _value) public onlyOwner onlyICO {
        uint256 tokens = _value.mul(10 ** DECIMALS).div(currentPrice);
        _checkMaxSaleSupply(tokens);
        _transferTokens(_to, tokens);
    }
    
    function getCountMembers() public constant returns(uint) {
        return countMembers;
    }
    
    function _transferTokens(address _to, uint256 _tokens) internal nonReentrant {
        _increaseTotalSupply(_tokens);
        token.transfer(_to, _tokens);
        emit Transfer(_to, _tokens);
    }
    
    function finalize() internal nonReentrant {
        token.approve(beneficiary, token.balanceOf(this));
    }
    
    function buyTokens() internal {
        require(msg.value != 0);
        
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(10 ** DECIMALS).div(currentPrice);
        
        _checkMaxSaleSupply(tokens);
        
        if (!whitelist[msg.sender]) {
            countMembers = countMembers.add(1);
            whitelist[msg.sender] = true;
        }
        
        totalFunds = totalFunds.add(weiAmount);
        _transferTokens(msg.sender, tokens);
    }
    
    function _checkMaxSaleSupply(uint256 tokens) internal {
        require(token.totalSupply().add(tokens) <= MAX_SUPPLY);
    }
    
    function _increaseTotalSupply(uint256 _tokens) internal {
        token.totalSupply = token.totalSupply().add(_tokens);
    }
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

contract TokenVault {
    uint256 public totalSupply;
    
    function transfer(address to, uint256 value) public returns(bool);
    function approve(address spender, uint256 value) public;
    function balanceOf(address who) public constant returns (uint256);
    function withdraw(address beneficiary, uint256 amount) public;
}

contract TokenTimelock {
    TokenVault public token;
    address public beneficiary;
    uint64 public releaseTime;
    
    function TokenTimelock(address _token, address _beneficiary, uint64 _releaseTime) public {
        require(_releaseTime > now);
        token = TokenVault(_token);
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }
    
    function release() public {
        require(now >= releaseTime);
        uint256 amount = token.balanceOf(this);
        require(amount > 0);
        token.withdraw(beneficiary, amount);
    }
}
```