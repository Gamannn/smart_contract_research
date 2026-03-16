```solidity
pragma solidity 0.4.25;

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract PaymentContract is Ownable {
    event Transfer(address indexed from, uint256 value);
    event Withdraw(address indexed to, uint256 value);
    
    function() payable public {
        require(msg.value > 0);
        require(msg.sender != address(0));
        emit Transfer(msg.sender, msg.value);
    }
    
    function withdraw(address to, uint256 amount) public onlyOwner {
        require(amount > 0);
        require(address(this).balance >= amount);
        require(to != address(0));
        
        to.transfer(amount);
        emit Withdraw(to, amount);
    }
}
```