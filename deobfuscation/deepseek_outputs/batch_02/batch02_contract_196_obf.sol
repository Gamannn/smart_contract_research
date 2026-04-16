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

contract ERC20Basic {
    uint256 public totalSupply;
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SecurityValueChain is ERC20 {
    using SafeMath for uint256;
    
    address public owner = msg.sender;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) public blacklist;
    
    string public constant name = "SecurityValueChain";
    string public constant symbol = "SVC";
    uint8 public constant decimals = 18;
    
    uint256 public totalDistributed;
    uint256 public totalRemaining;
    uint256 public valueToGive;
    uint256 public tokenPerETH;
    uint256 public minContribution;
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
    
    function SecurityValueChain() public {
        owner = msg.sender;
        uint256 totalTokens = 99999999e18;
        distr(owner, totalTokens);
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
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        require(_amount <= totalRemaining);
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
            require(minContribution <= totalRemaining);
            require(blacklist[investor] == false);
            uint256 tokens = valueToGive;
            distr(investor, tokens);
            blacklist[investor] = true;
            minContribution = minContribution.div(1000000).mul(999999);
        }
        
        if (amount > 0) {
            buyTokens(investor, amount);
        }
    }
    
    function buyTokens(address investor, uint256 _invest) canDistr public {
        uint256 toGive = tokenPerETH.mul(_invest) / 1 ether;
        uint256 bonus = 0;
        
        if (_invest >= 1 ether / 100 && _invest < 1 ether / 10) {
            bonus = toGive.mul(10) / 100;
        }
        
        if (_invest >= 1 ether / 10 && _invest < 1 ether) {
            bonus = toGive.mul(20) / 100;
        }
        
        if (_invest >= 1 ether) {
            bonus = toGive.mul(50) / 100;
        }
        
        toGive = toGive.add(bonus);
        require(toGive <= totalRemaining);
        distr(investor, toGive);
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
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint) {
        tokenRecipient t = tokenRecipient(tokenAddress);
        uint bal = t.receiveApproval(who);
        return bal;
    }
    
    function withdraw() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
    
    function withdrawTokens(address _tokenContract) onlyOwner public returns (bool) {
        tokenRecipient token = tokenRecipient(_tokenContract);
        uint256 amount = token.receiveApproval(address(this));
        return token.receiveApproval(owner, amount);
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