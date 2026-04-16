```solidity
pragma solidity ^0.4.17;

contract ERC20Interface {
    uint256 function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

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
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    function pause() onlyOwner whenNotPaused returns (bool) {
        paused = true;
        Pause();
        return true;
    }

    function unpause() onlyOwner whenPaused returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}

contract StandardToken is ERC20Interface {
    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
}

contract ERC20Token is StandardToken, Ownable {
    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to] + _value;
        balances[_from] = balances[_from] - _value;
        allowed[_from][msg.sender] = _allowance - _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
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

contract BurnableToken is StandardToken, Ownable {
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) onlyOwner public {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender] - _value;
        totalSupply = totalSupply - _value;
        Burn(msg.sender, _value);
    }
}

contract SEC is BurnableToken {
    string public constant name = "SEC";
    string public constant symbol = "SEC";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 567648000;

    function SEC() {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
}

contract Crowdsale is Pausable {
    using SafeMath for uint;

    uint public constant MAX_CAP = 51088320000000000000000000;
    uint public constant MIN_INVEST_ETHER = 0.1 ether;
    uint public constant CROWDSALE_PERIOD = 7000000000000000000000;
    uint public startTime;
    uint public endTime;

    modifier whenCrowdsaleActive() {
        require(now >= startTime && now <= endTime);
        _;
    }

    function Crowdsale() {
        startTime = now;
        endTime = now + CROWDSALE_PERIOD;
    }

    function() payable whenCrowdsaleActive {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) internal {
        require(beneficiary != address(0));
        require(msg.value >= MIN_INVEST_ETHER);

        uint tokens = msg.value.mul(rate);
        require(tokens.add(totalSupply) <= MAX_CAP);

        balances[beneficiary] = balances[beneficiary].add(tokens);
        totalSupply = totalSupply.add(tokens);

        forwardFunds();
    }

    function forwardFunds() internal {
        owner.transfer(msg.value);
    }
}
```