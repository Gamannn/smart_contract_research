```solidity
pragma solidity ^0.4.23;

contract ERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        
        uint256 previousBalances = balanceOf[from] + balanceOf[to];
        balanceOf[from] -= value;
        balanceOf[to] += value;
        
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
        Transfer(from, to, value);
    }
    
    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
}

contract BurnableToken is ERC20 {
    event Burn(address indexed burner, uint256 value);
    
    function burn(uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        Burn(msg.sender, value);
        return true;
    }
    
    function burnFrom(address from, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        allowance[from][msg.sender] -= value;
        totalSupply -= value;
        Burn(from, value);
        return true;
    }
}

contract ICO is ERC20 {
    uint256 public icoRate;
    uint256 public icoEndTime;
    address public icoSender;
    
    event ICO(address indexed participant, uint256 ethAmount, uint256 tokenAmount);
    
    modifier icoActive() {
        require(now <= icoEndTime);
        _;
    }
    
    function buyTokens() public payable icoActive {
        uint256 tokens = (msg.value * icoRate * 10 ** uint256(decimals)) / (1 ether);
        require(tokens > 0);
        _transfer(icoSender, msg.sender, tokens);
        ICO(msg.sender, msg.value, tokens);
    }
    
    function withdraw() public {
        uint256 balance = this.balance;
        icoSender.transfer(balance);
    }
}

contract TorkenToken is ERC20, BurnableToken, ICO {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    
    function TorkenToken() public {
        totalSupply = 10000000000000000000000000000;
        balanceOf[0x649F543994ae132aC04FdBBcDe523F107d79d995] = totalSupply;
        name = "Torken";
        symbol = "TKI";
        decimals = 18;
        icoRate = 10000;
        icoEndTime = 1677668400;
        icoSender = 0x649F543994ae132aC04FdBBcDe523F107d79d995;
        owner = msg.sender;
    }
}
```