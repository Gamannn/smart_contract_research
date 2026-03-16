```solidity
pragma solidity ^0.4.11;

contract SafeMath {
    function SafeMath() { }
    
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(a >= b);
        return a - b;
    }
    
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
}

contract IOwned {
    function owner() public constant returns (address) { owner; }
    function transferOwnership(address newOwner) public;
    function acceptOwnership() public;
}

contract Owned is IOwned {
    event OwnerUpdate(address previousOwner, address newOwner);
    
    address public owner;
    address public newOwner;
    
    function Owned() {
        owner = msg.sender;
    }
    
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract IERC20Token {
    function name() public constant returns (string) { name; }
    function symbol() public constant returns (string) { symbol; }
    function decimals() public constant returns (uint8) { decimals; }
    function totalSupply() public constant returns (uint256) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256) { _owner; _spender; remaining; }
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract ERC20Token is IERC20Token, SafeMath {
    string public standard = 'Token 0.1';
    string public name = '';
    string public symbol = '';
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function ERC20Token(string _name, string _symbol, uint8 _decimals) {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }
    
    function transfer(address _to, uint256 _value) public validAddress(_to) returns (bool success) {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public validAddress(_from) validAddress(_to) returns (bool success) {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public validAddress(_spender) returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

contract TokenHolder is ITokenHolder, Owned {
    function TokenHolder() { }
    
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }
    
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }
    
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public ownerOnly validAddress(_token) validAddress(_to) notThis(_to) {
        assert(_token.transfer(_to, _amount));
    }
}

contract IEtherToken is ITokenHolder, IERC20Token {
    function deposit() public payable;
    function withdraw(uint256 _amount) public;
}

contract EtherToken is IEtherToken, ERC20Token, Owned, TokenHolder {
    event Issuance(uint256 _amount);
    event Destruction(uint256 _amount);
    
    function EtherToken() ERC20Token('Ether Token', 'ETH', 18) { }
    
    function deposit() public payable {
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], msg.value);
        totalSupply = safeAdd(totalSupply, msg.value);
        Issuance(msg.value);
        Transfer(this, msg.sender, msg.value);
    }
    
    function withdraw(uint256 _amount) public {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _amount);
        totalSupply = safeSub(totalSupply, _amount);
        assert(msg.sender.send(_amount));
        Transfer(msg.sender, this, _amount);
        Destruction(_amount);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(this));
        assert(super.transfer(_to, _value));
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(this));
        assert(super.transferFrom(_from, _to, _value));
        return true;
    }
    
    function() public payable {
        deposit();
    }
}
```