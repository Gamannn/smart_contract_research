```solidity
pragma solidity ^0.4.22;

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

contract ERC20Basic {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) external;
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TREKToken is ERC20, Ownable {
    using SafeMath for uint256;

    string public constant name = "TREK";
    string public constant symbol = "TREK";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    uint256 public totalDistributed;
    uint256 public totalRemaining;
    bool public distributionFinished = false;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => bool) public whitelist;

    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event Burn(address indexed burner, uint256 value);

    modifier canDistr() {
        require(!distributionFinished);
        _;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender] == false);
        _;
    }

    constructor() public {
        owner = msg.sender;
        totalSupply = 1200000000e18;
        totalDistributed = 0;
        totalRemaining = totalSupply;
    }

    function distribute(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
        return true;
    }

    function () external payable {
        getTokens();
    }

    function getTokens() payable canDistr onlyWhitelist public {
        uint256 toGive = 100000e18.div(99999);
        address investor = msg.sender;
        uint256 toDistribute = toGive;
        distribute(investor, toDistribute);
        if (toDistribute > 0) {
            whitelist[investor] = true;
        }
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }

    function withdrawTokens(address _tokenContract) onlyOwner public returns (bool) {
        ERC20 token = ERC20(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}
```