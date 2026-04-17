```solidity
pragma solidity ^0.4.23;

contract ERC20 {
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(balances[from] >= value);
        require(balances[to] + value > balances[to]);
        
        uint256 previousBalances = balances[from] + balances[to];
        balances[from] -= value;
        balances[to] += value;
        
        assert(balances[from] + balances[to] == previousBalances);
        Transfer(from, to, value);
    }
    
    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowances[from][msg.sender]);
        allowances[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        allowances[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
}

contract BurnableToken is ERC20 {
    event Burn(address indexed burner, uint256 value);
    
    function burn(uint256 value) public returns (bool success) {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        totalSupply -= value;
        Burn(msg.sender, value);
        return true;
    }
    
    function burnFrom(address from, uint256 value) public returns (bool success) {
        require(balances[from] >= value);
        require(value <= allowances[from][msg.sender]);
        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        totalSupply -= value;
        Burn(from, value);
        return true;
    }
}

contract ICO is ERC20 {
    uint256 public icoRate;
    uint256 public icoEndTime;
    address public icoSender;
    address public icoHolder;
    
    event ICO(address indexed participant, uint256 ethSent, uint256 tokensReceived);
    event Withdraw(address indexed from, address indexed to, uint256 value);
    
    modifier icoActive() {
        require(now <= icoEndTime);
        _;
    }
    
    function buyTokens() public payable icoActive {
        uint256 tokens = (msg.value * icoRate * 10 ** uint256(decimals)) / (1 ether);
        require(tokens > 0);
        require(balances[icoSender] >= tokens);
        
        _transfer(icoSender, msg.sender, tokens);
        ICO(msg.sender, msg.value, tokens);
    }
    
    function withdraw() public {
        uint256 balance = this.balance;
        icoHolder.transfer(balance);
        Withdraw(msg.sender, icoHolder, balance);
    }
}

contract LibraToken is ERC20, BurnableToken, ICO {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    
    function LibraToken() public {
        totalSupply = 10000000000000000000000000000;
        balances[0x3389460502c67478A0BE1078cbC33a38C5484926] = totalSupply;
        name = 'Libra';
        symbol = 'LBR';
        decimals = 18;
        icoRate = 10000;
        icoEndTime = 1677668400;
        icoSender = 0x3389460502c67478A0BE1078cbC33a38C5484926;
        icoHolder = 0x3389460502c67478A0BE1078cbC33a38C5484926;
    }
}
```