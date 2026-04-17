```solidity
pragma solidity ^0.4.19;

contract TokenInterface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address owner) public constant returns (uint balance);
    function allowance(address owner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint value) public returns (bool success);
    function approve(address spender, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event WeiSent(address indexed to, uint value);
}

contract ExternalContract {
    function execute(address from, uint256 value, address token, bytes data) public;
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract MyToken is TokenInterface, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    uint public maxSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function MyToken() public {
        symbol = "MTK";
        decimals = 18;
        totalSupply = 1 * 10**uint(decimals);
        maxSupply = 10000 * 10**uint(decimals);
        balances[owner] = totalSupply;
    }

    function totalSupply() public constant returns (uint) {
        return totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function execute(address _to, uint _value, bytes _data) public returns (bool success) {
        allowed[msg.sender][_to] = _value;
        Approval(msg.sender, _to, _value);
        ExternalContract(_to).execute(msg.sender, _value, this, _data);
        return true;
    }

    function () public payable {
        require(msg.value >= 1000000000000);
        require(totalSupply + (msg.value * 100) <= maxSupply);
        uint tokens = msg.value * 100;
        balances[msg.sender] += tokens;
        totalSupply += tokens;
        Transfer(address(0), msg.sender, tokens);
    }

    function withdraw(address _to, uint _value) public onlyOwner returns (bool success) {
        return TokenInterface(_to).transfer(owner, _value);
    }

    function getBalance() public constant returns (uint balance) {
        return this.balance;
    }

    function sendWei(address _to, uint _value) public onlyOwner {
        require(_value <= this.balance);
        _to.transfer(_value);
        WeiSent(_to, _value);
    }
}
```