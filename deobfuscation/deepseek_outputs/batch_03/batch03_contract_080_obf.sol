```solidity
pragma solidity ^0.4.18;

contract SimpleWallet {
    address public owner;
    
    function SimpleWallet() payable {
        owner = msg.sender;
    }
    
    function withdraw() payable onlyOwner {
        owner.transfer(this.balance - msg.value);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}
```