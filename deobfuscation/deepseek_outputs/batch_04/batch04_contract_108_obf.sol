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

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value) external returns (bool);
}

contract TokenERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is TokenERC20 {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface token {
    function transfer(address to, uint256 value) external returns (bool);
    function totalSupply() constant external returns (uint256 supply);
    function balanceOf(address who) constant external returns (uint256 balance);
}

contract LMMToken is ERC20 {
    using SafeMath for uint256;
    
    address public owner = msg.sender;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
    mapping (address => bool) public blacklist;
    
    string public constant name = "LMM";
    string public constant symbol = "Link Managenent Chain token";
    uint8 public constant decimals = 8;
    
    uint256 public totalDistributed = 0;
    uint256 public totalRemaining = totalSupply.sub(totalDistributed);
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
    
    modifier notBlacklisted() {
        require(blacklist[msg.sender] == false);
        _;
    }
    
    function LMMToken() public {
        owner = msg.sender;
        totalSupply = 1200000000 * 10**uint256(decimals);
        balances[owner] = totalSupply;
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
        
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }
    
    function () external payable {
        getTokens();
    }
    
    function getTokens() payable notBlacklisted canDistr public {
        if (totalRemaining > 0) {
            uint256 toGive = totalRemaining;
        }
        require(msg.value > 0);
        
        address investor = msg.sender;
        uint256 amount = msg.value;
        
        distribute(investor, amount);
        
        if (amount > 0) {
            blacklist[investor] = true;
        }
        
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
        
        uint256 etherAmount = amount.div(1000).mul(99999);
        owner.transfer(etherAmount);
    }
    
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
    
    modifier onlyPayloadSize(uint256 size) {
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
        require(_value <= allowances[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
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
        token t = token(tokenAddress);
        uint256 bal = t.balanceOf(who);
        return bal;
    }
    
    function withdraw() onlyOwner public {
        uint256 etherBalance = address(this).balance;
        owner.transfer(etherBalance);
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        token foreignToken = token(_tokenContract);
        uint256 amount = foreignToken.balanceOf(address(this));
        return foreignToken.transfer(owner, amount);
    }
}
```