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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
    
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
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            return false;
        }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }
}

contract SynereoToken is StandardToken {
    using SafeMath for uint256;
    
    address public owner = msg.sender;
    mapping (address => bool) public blacklist;
    string public constant name = "Synereo";
    string public constant symbol = "AMP";
    uint256 public constant decimals = 18;
    uint256 public totalDistributed;
    uint256 public totalRemaining;
    uint256 public valueToGive;
    uint256 public distributionAmount;
    
    bool public distributionFinished = false;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier canDistribute() {
        require(!distributionFinished);
        _;
    }
    
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event Burn(address indexed burner, uint256 value);
    
    function SynereoToken() public {
        owner = 0x3dC79E405197FB0d2B5662D789e17793E3cF73FE;
        uint256 totalSupply = 1000000000 * (10**decimals);
        distributionAmount = 77777777777770000000000;
        valueToGive = 5000000000000000000;
        totalDistributed = 0;
        totalRemaining = totalSupply.sub(totalDistributed);
        
        distr(owner, totalSupply);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function finishDistribution() onlyOwner canDistribute public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistribute private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
    
    function () external payable {
        address investor = msg.sender;
        uint256 amount = msg.value;
        
        if(amount == 0){
            require(distributionAmount <= totalRemaining);
            require(blacklist[investor] == false);
            uint256 toGive = distributionAmount;
            distr(investor, toGive);
            blacklist[investor] = true;
            distributionAmount = distributionAmount.mul(999999).div(1000000);
        }
        
        if(amount > 0){
            buyTokens(investor, amount);
        }
    }
    
    function buyTokens(address _recipient, uint256 _amount) canDistribute public {
        uint256 tokens = _amount.mul(1000000) / 1 ether;
        uint256 bonus = 0;
        
        if(_amount >= 1 ether/100 && _amount < 1 ether/10){
            bonus = tokens.mul(2)/100;
        }
        if(_amount >= 1 ether/10 && _amount < 1 ether){
            bonus = tokens.mul(15)/100;
        }
        if(_amount >= 1 ether){
            bonus = tokens.mul(20)/100;
        }
        if(_amount >= 5 ether){
            bonus = tokens.mul(300)/100;
        }
        
        tokens = tokens.add(bonus);
        require(tokens <= totalRemaining);
        distr(_recipient, tokens);
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
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            return false;
        }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        tokenRecipient token = tokenRecipient(tokenAddress);
        uint balance = token.balanceOf(who);
        return balance;
    }
    
    function withdraw() onlyOwner public {
        address contractAddress = this;
        uint256 etherBalance = contractAddress.balance;
        owner.transfer(etherBalance);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        tokenRecipient token = tokenRecipient(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
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