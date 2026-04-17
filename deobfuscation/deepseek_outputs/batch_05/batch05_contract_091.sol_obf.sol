```solidity
pragma solidity ^0.4.19;

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
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

contract ICO is ERC20 {
    uint256 public icoEndTime;
    uint256 public icoRate;
    address public icoHolder;
    address public icoSender;
    
    event ICO(address indexed buyer, uint256 indexed ethAmount, uint256 tokenAmount);
    event Withdraw(address indexed from, address indexed to, uint256 value);
    
    modifier icoActive() {
        if (now > icoEndTime) {
            icoEndTime = now;
        }
        _;
    }
    
    function() public payable icoActive {
        uint256 tokenAmount = (msg.value * icoRate * 10 ** uint256(decimals)) / (1 ether / 1 wei);
        
        if (tokenAmount == 0 || balanceOf[icoSender] < tokenAmount) {
            revert();
        }
        
        _transfer(icoSender, msg.sender, tokenAmount);
        ICO(msg.sender, msg.value, tokenAmount);
    }
    
    function withdraw() public {
        uint256 balance = this.balance;
        icoHolder.transfer(balance);
        Withdraw(msg.sender, icoHolder, balance);
    }
}

contract CustomToken is ERC20, ICO {
    function CustomToken() public {
        totalSupply = 210000000000000000000000000;
        balanceOf[0xf043ae16a61ece2107eb2b] = totalSupply;
        name = 'BGCoin';
        symbol = 'BGC';
        decimals = 18;
        icoRate = 88888;
        icoEndTime = 1519812000;
        icoSender = 0xf043ae16a61ece2107eb2b;
        icoHolder = 0xf043ae16a61ece2107eb2b;
    }
}
```