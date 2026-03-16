```solidity
pragma solidity ^0.4.11;

contract hodlEthereum {
    event Hodl(address indexed hodler, uint indexed amount);
    event Party(address indexed hodler, uint indexed amount);
    
    mapping(address => uint) public hodlers;
    uint constant public RELEASE_TIME = 1596067200;
    
    function() external payable {
        hodlers[msg.sender] += msg.value;
        Hodl(msg.sender, msg.value);
    }
    
    function withdraw() external {
        require(block.timestamp > RELEASE_TIME);
        require(hodlers[msg.sender] > 0);
        
        uint amount = hodlers[msg.sender];
        hodlers[msg.sender] = 0;
        
        msg.sender.transfer(amount);
        Party(msg.sender, amount);
    }
}
```