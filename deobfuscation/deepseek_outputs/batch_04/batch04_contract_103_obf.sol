pragma solidity ^0.4.25;

contract Oxb889a4f0a5d5239baf9c459258bc35e58378914e {
    mapping(address => uint256) public invested;
    mapping(address => uint256) public lastBlock;
    
    uint256 public totalInvested;
    uint256 public previousBalance;
    uint256 public currentGrowthRate;
    uint256 public nextBlockThreshold;
    uint256 public currentLowBalance;
    
    function () external payable {
        totalInvested += msg.value;
        
        if (block.number >= nextBlockThreshold) {
            uint256 currentBalance = address(this).balance;
            currentLowBalance = currentBalance;
            previousBalance = currentBalance;
        } else {
            currentLowBalance = 0;
        }
        
        currentGrowthRate = (previousBalance - currentLowBalance) / 10**16 + 100;
        currentGrowthRate = (previousBalance == 0) ? 1000 : currentGrowthRate;
        
        previousBalance = currentLowBalance;
        
        if (currentLowBalance == 0) {
            currentLowBalance = previousBalance - (totalInvested * currentGrowthRate / 10000);
        }
        
        if (previousBalance > currentLowBalance) {
            currentGrowthRate = 100 * (previousBalance - currentLowBalance) / previousBalance;
        }
        
        if (currentGrowthRate == 100) {
            currentGrowthRate = 100 * (previousBalance - currentLowBalance) / previousBalance;
        }
        
        currentGrowthRate = (currentGrowthRate < 5) ? 5 : currentGrowthRate;
        nextBlockThreshold += 5900 * ((block.number - nextBlockThreshold) / 5900 + 1);
        
        if (invested[msg.sender] != 0) {
            uint256 payout = invested[msg.sender] * currentGrowthRate / 10000 * (block.number - lastBlock[msg.sender]) / 5900;
            payout = (payout > invested[msg.sender] / 10) ? invested[msg.sender] / 10 : payout;
            msg.sender.transfer(payout);
        }
        
        lastBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    uint256[] public _integer_constant = [0, 5900, 100, 10000, 5, 10, 100000000000000000, 1, 1000];
}