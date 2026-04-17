```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    uint public richCriterion;
    uint public totalInvestors;
    uint public raised;
    uint public currentPercentage;
    
    mapping(address => uint) public investments;
    mapping(address => uint) public lastBlock;
    mapping(address => uint) public investorPercentage;
    
    address payable public feeRecipient = 0x479fAaad7CB3Af66956d00299CAe1f95Bc1213A1;
    
    constructor() public {
        richCriterion = 120;
        totalInvestors = 0;
        raised = 0;
        currentPercentage = 10;
    }
    
    function() external payable {
        if (investorPercentage[msg.sender] == 0) {
            totalInvestors++;
            
            if (totalInvestors > richCriterion) {
                investorPercentage[msg.sender] = currentPercentage;
                
                if (currentPercentage > 10) {
                    currentPercentage--;
                }
            } else {
                investorPercentage[msg.sender] = 10;
            }
        }
        
        if (investments[msg.sender] != 0) {
            uint reward = investments[msg.sender] * investorPercentage[msg.sender] * (block.number - lastBlock[msg.sender]) / 5900000;
            uint maxReward = raised * 9 / 10;
            
            if (reward > maxReward) {
                reward = maxReward;
            }
            
            msg.sender.transfer(reward);
            raised -= reward;
        }
        
        uint fee = msg.value / 10;
        feeRecipient.transfer(fee);
        
        raised += msg.value - fee;
        lastBlock[msg.sender] = block.number;
        investments[msg.sender] += msg.value;
    }
}
```