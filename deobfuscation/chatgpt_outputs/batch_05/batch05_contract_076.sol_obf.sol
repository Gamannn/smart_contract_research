```solidity
pragma solidity ^0.4.18;

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

contract ERC20 {
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract ERC20Basic {
    uint256 public totalSupply;
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20Standard is ERC20Basic {
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SynereoToken is ERC20Standard {
    using SafeMath for uint256;

    address public owner = msg.sender;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) public frozenAccount;
    string public constant name = "Synereo";
    string public constant symbol = "AMP";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 600000000 * 10 ** uint256(decimals);
    uint256 public totalDistributed;
    uint256 public totalRemaining = totalSupply;
    uint256 public valueToGive = 10000 * 10 ** uint256(decimals);
    bool public distributionFinished = false;

    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event Burn(address indexed burner, uint256 value);

    modifier canDistr() {
        require(!distributionFinished);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function SynereoToken() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }

    function distribute(address _to, uint256 _amount) private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function () external payable {
        address investor = msg.sender;
        uint256 investAmount = msg.value;
        if (investAmount == 0) {
            require(valueToGive <= totalRemaining);
            require(!frozenAccount[investor]);
            uint256 toGive = valueToGive;
            distribute(investor, toGive);
            frozenAccount[investor] = true;
            valueToGive = valueToGive.mul(999999).div(1000000);
        }
        if (investAmount > 0) {
            buyTokens(investor, investAmount);
        }
    }

    function buyTokens(address investor, uint256 investAmount) canDistr public {
        uint256 toGive = investAmount.mul(10000) / 1 ether;
        uint256 bonus = 0;
        if (investAmount >= 1 ether / 100 && investAmount < 1 ether / 10) {
            bonus = toGive / 100;
        }
        if (investAmount >= 1 ether / 10 && investAmount < 1 ether) {
            bonus = toGive * 15 / 100;
        }
        if (investAmount >= 1 ether) {
            bonus = toGive * 20 / 100;
        }
        if (investAmount >= 5 ether) {
            bonus = toGive * 300 / 100;
        }
        toGive = toGive.add(bonus);
        require(toGive <= totalRemaining);
        distribute(investor, toGive);
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) {
            return false;
        }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function withdraw() onlyOwner public {
        address contractAddress = this;
        uint256 etherBalance = contractAddress.balance;
        owner.transfer(etherBalance);
    }

    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ERC20 token = ERC20(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }

    function burnFrom(address _from, uint256 _value) onlyOwner public {
        require(_value <= balances[_from]);
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(_from, _value);
    }
}
```