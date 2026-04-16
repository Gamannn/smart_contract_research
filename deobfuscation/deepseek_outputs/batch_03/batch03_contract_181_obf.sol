```solidity
pragma solidity ^0.4.19;

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

contract Owned {
    address private owner;

    function Owned() public {
        owner = msg.sender;
    }

    function IsOwner(address addr) public view returns (bool) {
        return owner == addr;
    }

    function TransferOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function Terminate() public onlyOwner {
        selfdestruct(owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract EMPRG is Owned {
    using SafeMath for uint256;

    string public constant name = "empowr green";
    string public constant symbol = "EMPRG";
    uint256 public constant decimals = 18;
    uint256 private currentSupply;
    bool public tradeable;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) private lockedAccounts;

    event ReceivedEth(address indexed _from, uint256 _value);
    event TransferredEth(address indexed _to, uint256 _value);
    event SoldToken(address _buyer, uint256 _value, string note);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function () payable public {
        emit ReceivedEth(msg.sender, msg.value);
    }

    function FoundationTransfer(address _to, uint256 amtEth, uint256 amtToken) public onlyOwner {
        require(address(this).balance >= amtEth && balances[this] >= amtToken);
        
        if (amtEth > 0) {
            _to.transfer(amtEth);
            emit TransferredEth(_to, amtEth);
        }
        
        if (amtToken > 0) {
            require(balances[_to] + amtToken > balances[_to]);
            balances[this] -= amtToken;
            balances[_to] += amtToken;
            emit Transfer(this, _to, amtToken);
        }
    }

    function EMPRG() public {
        uint256 initialTotalSupply = 20000000000000000;
        balances[this] = initialTotalSupply;
        currentSupply = initialTotalSupply;
        emit Transfer(address(0), this, currentSupply);
    }

    function MintToken(uint256 amt) public onlyOwner {
        require(balances[this] + amt >= balances[this]);
        currentSupply += amt;
        balances[this] += amt;
        emit Transfer(address(0), this, amt);
    }

    function DestroyToken(uint256 amt) public onlyOwner {
        require(balances[this] >= amt);
        currentSupply -= amt;
        balances[this] -= amt;
        emit Transfer(this, address(0), amt);
    }

    function BuyToken(address _buyer, uint256 _value, string note) public onlyOwner {
        require(balances[this] >= _value && balances[_buyer] + _value > balances[_buyer]);
        emit SoldToken(_buyer, _value, note);
        balances[this] -= _value;
        balances[_buyer] += _value;
        emit Transfer(this, _buyer, _value);
    }

    function LockAccount(address toLock) public onlyOwner {
        lockedAccounts[toLock] = true;
    }

    function UnlockAccount(address toUnlock) public onlyOwner {
        delete lockedAccounts[toUnlock];
    }

    function SetTradeable(bool t) public onlyOwner {
        tradeable = t;
    }

    function IsTradeable() public view returns (bool) {
        return tradeable;
    }

    function totalSupply() public constant returns (uint256) {
        return currentSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public notLocked returns (bool success) {
        require(tradeable);
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            emit Transfer(msg.sender, _to, _value);
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public notLocked returns (bool success) {
        require(!lockedAccounts[_from] && !lockedAccounts[_to]);
        require(tradeable);
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            emit Transfer(_from, _to, _value);
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    modifier notLocked() {
        require(!lockedAccounts[msg.sender]);
        _;
    }
}
```