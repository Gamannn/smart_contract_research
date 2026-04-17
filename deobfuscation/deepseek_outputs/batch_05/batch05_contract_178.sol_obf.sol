pragma solidity ^0.4.25;

contract Gainz {
    address private owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastBlock;
    
    function() external payable {
        owner.transfer(msg.value / 20);
        
        if (balances[msg.sender] != 0) {
            msg.sender.transfer(getPendingReward(msg.sender));
        }
        
        lastBlock[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
    }
    
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }
    
    function getPendingReward(address user) public view returns (uint256) {
        uint256 blocksPassed = block.number - lastBlock[user];
        return balances[user] * 2 / 100 * blocksPassed / 6000;
    }
}