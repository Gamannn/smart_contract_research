```solidity
pragma solidity ^0.4.22;

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
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ETHERCHIP is ERC20 {
    using SafeMath for uint256;
    
    address public owner = msg.sender;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => bool) blacklist;
    
    string public constant name = "ETHER Chip";
    string public constant symbol = "ECHIP";
    uint256 public constant decimals = 18;
    
    uint256 public totalDistributed;
    uint256 public totalRemaining;
    uint256 public valueToGive = 1000000;
    uint256 public tokenPerETH = 1000e18;
    
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
    
    function ETHERCHIP() public {
        uint256 totalSupplyAmount = 2500000000 * (10**decimals);
        totalRemaining = totalSupplyAmount;
        distribute(owner, totalSupplyAmount);
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
        uint256 investAmount = msg.value;
        
        if (investAmount == 0) {
            require(valueToGive <= totalRemaining);
            require(blacklist[investor] == false);
            
            uint256 toGive = valueToGive;
            distribute(investor, toGive);
            blacklist[investor] = true;
            
            valueToGive = valueToGive.div(1000000).mul(999999);
        }
        
        if (investAmount > 0) {
            buyTokens(investor, investAmount);
        }
    }
    
    function buyTokens(address investor, uint256 investAmount) canDistr public {
        uint256 toGive = tokenPerETH.mul(investAmount) / 1 ether;
        uint256 bonus = 0;
        
        if (investAmount >= 1 ether/100 && investAmount < 1 ether/10) {
            bonus = toGive.mul(10).div(100);
        }
        
        if (investAmount >= 1 ether/10 && investAmount < 1 ether) {
            bonus = toGive.mul(20).div(100);
        }
        
        if (investAmount >= 1 ether) {
            bonus = toGive.mul(30).div(100);
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
        tokenRecipient t = tokenRecipient(tokenAddress);
        uint256 bal = t.receiveApproval(who);
        return bal;
    }
    
    function withdraw() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        tokenRecipient token = tokenRecipient(_tokenContract);
        uint256 amount = token.receiveApproval(address(this));
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