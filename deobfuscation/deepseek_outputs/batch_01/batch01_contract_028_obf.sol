```solidity
pragma solidity ^0.4.25;

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
}

contract owned {
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract CRP_ERC20 is owned {
    using SafeMath for uint256;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozenAccount;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event BuyRateChanged(uint256 oldValue, uint256 newValue);
    event SellRateChanged(uint256 oldValue, uint256 newValue);
    event BuyToken(address user, uint256 eth, uint256 token);
    event SellToken(address user, uint256 eth, uint256 token);
    event LogDepositMade(address indexed accountAddress, uint256 amount);
    event FrozenFunds(address target, bool frozen);
    event SellTokenAllowedEvent(bool isAllowed);
    
    bool public SellTokenAllowed;
    uint256 public TokenPerETHSell;
    uint256 public TokenPerETHBuy;
    uint256 public totalSupply;
    uint8 public decimals;
    string public name;
    string public symbol;
    address public owner;
    
    constructor() public {
        decimals = 18;
        name = "CRP";
        symbol = "Chiwoo Rotary Press";
        owner = msg.sender;
        totalSupply = 8000000000 * 10 ** uint256(decimals);
        balanceOf[owner] = totalSupply;
        SellTokenAllowed = true;
        TokenPerETHSell = 1000;
        TokenPerETHBuy = 1000;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_from, _value);
        return true;
    }
    
    function setBuyRate(uint256 _rate) onlyOwner public {
        require(_rate > 0);
        emit BuyRateChanged(TokenPerETHBuy, _rate);
        TokenPerETHBuy = _rate;
    }
    
    function setSellRate(uint256 _rate) onlyOwner public {
        require(_rate > 0);
        emit SellRateChanged(TokenPerETHSell, _rate);
        TokenPerETHSell = _rate;
    }
    
    function buy() payable public returns (uint256 amount) {
        require(msg.value > 0);
        require(!frozenAccount[msg.sender]);
        
        amount = (msg.value.mul(TokenPerETHBuy).mul(10 ** uint256(decimals))).div(1 ether);
        balanceOf[this] = balanceOf[this].sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        
        emit Transfer(this, msg.sender, amount);
        return amount;
    }
    
    function sell(uint256 amount) public returns (uint256 revenue) {
        require(balanceOf[msg.sender] >= amount);
        require(SellTokenAllowed);
        require(!frozenAccount[msg.sender]);
        
        balanceOf[this] = balanceOf[this].add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        
        revenue = (amount.mul(1 ether)).div(TokenPerETHSell.mul(10 ** uint256(decimals)));
        msg.sender.transfer(revenue);
        
        emit Transfer(msg.sender, this, amount);
        return revenue;
    }
    
    function deposit() public payable {
    }
    
    function withdraw(uint256 withdrawAmount) onlyOwner public {
        if (withdrawAmount <= address(this).balance) {
            owner.transfer(withdrawAmount);
        }
    }
    
    function() public payable {
        buy();
    }
    
    function enableSellToken() onlyOwner public {
        SellTokenAllowed = true;
        emit SellTokenAllowedEvent(true);
    }
    
    function disableSellToken() onlyOwner public {
        SellTokenAllowed = false;
        emit SellTokenAllowedEvent(false);
    }
}
```