```solidity
pragma solidity ^0.4.0;

contract Ownable {
    address public owner;
    
    function Ownable() payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract ERC20Basic is Ownable {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function ERC20Basic() payable Ownable() {
        totalSupply = 21000000;
        balanceOf[owner] = 20000000;
        balanceOf[this] = totalSupply - balanceOf[owner];
        Transfer(this, owner, balanceOf[owner]);
    }
    
    function() payable {
        require(balanceOf[this] > 0);
        
        uint256 tokensPerOneEther = 3000;
        uint256 tokens = tokensPerOneEther * msg.value / 1000000000000000000;
        
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint256 refund = tokens * 1000000000000000000 / tokensPerOneEther;
            msg.sender.transfer(msg.value - refund);
        }
        
        require(tokens > 0);
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        Transfer(this, msg.sender, tokens);
    }
}

contract ERC20 is ERC20Basic {
    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
    }
}

contract Token is ERC20 {
    function Token() payable ERC20() {}
    
    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}
```