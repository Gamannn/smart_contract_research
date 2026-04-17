pragma solidity ^0.4.25;

contract GainzGame {
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    mapping(address => uint) public balances;
    mapping(address => uint) public lastBlock;
    
    function() external payable {
        owner.transfer(msg.value / 20); // 5% fee to the owner
        
        if (balances[msg.sender] != 0) {
            uint amountOwed = calculateOwed(msg.sender);
            msg.sender.transfer(amountOwed);
        }
        
        lastBlock[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
    }
    
    function getBalance(address user) public view returns (uint) {
        return balances[user];
    }
    
    function calculateOwed(address user) public view returns (uint) {
        uint blocksPassed = block.number - lastBlock[user];
        return balances[user] * 2 / 100 * blocksPassed / 6000;
    }
}