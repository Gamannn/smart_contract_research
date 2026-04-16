```solidity
pragma solidity ^0.4.13;

contract Ownable {
    address public owner;
    
    function Ownable() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint a, uint b) internal returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }
    
    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }
    
    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
    
    function require(bool condition) internal {
        if (!condition) {
            revert();
        }
    }
}

contract ERC20 {
    function totalSupply() constant returns (uint256 totalSupply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract PotatoCoin is ERC20, SafeMath, Ownable {
    mapping(address => uint256) balances;
    uint256 public totalSupply;
    uint256 public buyPrice;
    
    string public name = "Potato Coin";
    string public symbol = "PTCN";
    uint public decimals = 0;
    uint public INITIAL_SUPPLY = 50000;
    uint public MAX_SUPPLY = 50000000;
    
    mapping (address => mapping (address => uint256)) allowed;
    
    function PotatoCoin() {
        buyPrice = 280;
        balances[this] = INITIAL_SUPPLY;
        totalSupply = INITIAL_SUPPLY;
    }
    
    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        var _allowance = allowed[_from][msg.sender];
        
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
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
    
    function buy() payable {
        uint amount = safeDiv(safeMul(msg.value, buyPrice), 1 ether);
        allowed[this][msg.sender] = amount;
        transferFrom(this, msg.sender, amount);
    }
    
    function setPrice(uint256 newPrice) onlyOwner {
        buyPrice = newPrice;
    }
    
    function mint(uint amount) onlyOwner {
        totalSupply = safeAdd(totalSupply, amount);
        balances[this] = safeAdd(balances[this], amount);
    }
    
    function destroy() onlyOwner {
        suicide(owner);
    }
    
    function allocate(address recipient, uint amount) onlyOwner {
        transfer(recipient, amount);
    }
    
    function () payable {
        uint amount = safeDiv(safeMul(msg.value, buyPrice), 1 ether);
        allowed[this][msg.sender] = amount;
        transferFrom(this, msg.sender, amount);
    }
}
```