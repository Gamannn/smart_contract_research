```solidity
pragma solidity ^0.4.18;

contract WETH {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event Deposit(address indexed to, uint value);
    event Withdrawal(address indexed from, uint value);
    
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    
    function() public payable {
        deposit();
    }
    
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint value) public {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        msg.sender.transfer(value);
        Withdrawal(msg.sender, value);
    }
    
    function totalSupply() public view returns (uint) {
        return this.balance;
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function transfer(address to, uint value) public returns (bool) {
        return transferFrom(msg.sender, to, value);
    }
    
    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(balanceOf[from] >= value);
        
        if (from != msg.sender && allowance[from][msg.sender] != uint(-1)) {
            require(allowance[from][msg.sender] >= value);
            allowance[from][msg.sender] -= value;
        }
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        Transfer(from, to, value);
        return true;
    }
}
```