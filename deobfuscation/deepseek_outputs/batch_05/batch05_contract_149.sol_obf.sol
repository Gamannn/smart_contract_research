```solidity
pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value) external returns (bool);
}

contract TokenERC20 {
    uint256 public totalSupply;
    
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is TokenERC20 {
    function allowance(address _owner, address _spender) public constant returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SVChain is ERC20 {
    using SafeMath for uint256;
    
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => bool) public blacklist;
    
    string public constant name = "SVChain";
    string public constant symbol = "SVChain";
    uint8 public constant decimals = 18;
    
    uint256 public totalDistributed;
    uint256 public totalRemaining;
    uint256 public valueToGive = 25000e18;
    uint256 public tokenPerETH = 25000e18;
    uint256 public minContribution = 1 ether / 100;
    uint256 public maxContribution = 1 ether;
    
    bool public distributionFinished = false;
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event Burn(address indexed burner, uint256 value);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        uint256 initialSupply = 2000000000e18;
        totalDistributed = 0;
        totalRemaining = initialSupply;
        balances[owner] = initialSupply;
        totalSupply = initialSupply;
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
    
    function distribute(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
    
    function () external payable {
        address investor = msg.sender;
        uint256 amount = msg.value;
        
        if (amount == 0) {
            require(valueToGive <= totalRemaining);
            require(blacklist[investor] == false);
            uint256 toGive = valueToGive;
            distribute(investor, toGive);
            blacklist[investor] = true;
            valueToGive = valueToGive.div(1000000).mul(999999);
        }
        
        if (amount > 0) {
            buyTokens(investor, amount);
        }
    }
    
    function buyTokens(address investor, uint256 amount) canDistr public {
        uint256 toGive = tokenPerETH.mul(amount) / 1 ether;
        uint256 bonus = 0;
        
        if (amount >= minContribution && amount < maxContribution / 10) {
            bonus = toGive.mul(1) / 100;
        }
        
        if (amount >= maxContribution / 10 && amount < maxContribution) {
            bonus = toGive.mul(10) / 100;
        }
        
        if (amount >= maxContribution) {
            bonus = toGive.mul(40) / 100;
        }
        
        toGive = toGive.add(bonus);
        require(toGive <= totalRemaining);
        distribute(investor, toGive);
    }
    
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowances[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        if (_value != 0 && allowances[msg.sender][_spender] != 0) {
            return false;
        }
        
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowances[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint256) {
        TokenERC20 token = TokenERC20(tokenAddress);
        uint256 balance = token.balanceOf(who);
        return balance;
    }
    
    function withdraw() onlyOwner public {
        address contractAddress = this;
        uint256 etherBalance = contractAddress.balance;
        owner.transfer(etherBalance);
    }
    
    function withdrawTokens(address tokenAddress) onlyOwner public returns (bool) {
        TokenERC20 token = TokenERC20(tokenAddress);
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
    
    function burnFrom(uint256 _value, address _burner) onlyOwner public {
        require(_value <= balances[_burner]);
        balances[_burner] = balances[_burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(_burner, _value);
    }
}
```