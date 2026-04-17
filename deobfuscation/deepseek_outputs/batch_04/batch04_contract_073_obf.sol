```solidity
pragma solidity ^0.4.10;

contract InvestmentPool {
    mapping(address => uint) public registrationTime;
    mapping(address => uint) public investedAmount;
    mapping(address => uint) public lastCumulativeRatio;
    
    uint public constant LARGE_CONSTANT = 1000000000000000000000000;
    uint public constant DIVISOR = 50400;
    uint public constant PERCENT_DIVISOR = 10;
    
    uint public cumulativeRatioTotal;
    uint public totalInvested;
    uint public participantCount;
    
    mapping(uint => address) public participantIndex;
    
    function InvestmentPool() {
        // Constructor
    }
    
    function _registerParticipant(address participant) private {
        if (registrationTime[participant] == 0) {
            participantIndex[participantCount] = participant;
            participantCount++;
            registrationTime[participant] = now;
        }
    }
    
    function _updateInvestment(address participant, uint amountChange) private {
        investedAmount[participant] = investedAmount[participant] + amountChange;
        totalInvested = totalInvested + amountChange;
    }
    
    function _updateCumulativeRatio(uint reward, uint totalInvestment) private {
        if (totalInvestment > 0) {
            cumulativeRatioTotal = cumulativeRatioTotal + (reward * LARGE_CONSTANT) / totalInvestment;
        }
    }
    
    function _updateLastCumulativeRatio(address participant) private {
        lastCumulativeRatio[participant] = cumulativeRatioTotal;
    }
    
    function calculateReward(address participant) constant returns (uint) {
        uint cumulativeRatioDiff = cumulativeRatioTotal - lastCumulativeRatio[participant];
        uint reward = (cumulativeRatioDiff * investedAmount[participant]) / LARGE_CONSTANT;
        
        uint penaltyAmount = investedAmount[participant] / PERCENT_DIVISOR;
        uint penalty = (penaltyAmount * DIVISOR) / totalInvested;
        
        return reward - penalty;
    }
    
    function register() {
        registrationTime[msg.sender] = now;
    }
    
    function invest() payable {
        uint pendingReward = calculateReward(msg.sender);
        _registerParticipant(msg.sender);
        _updateInvestment(msg.sender, msg.value);
        _updateLastCumulativeRatio(msg.sender);
        _updateCumulativeRatio(pendingReward, totalInvested);
    }
    
    function withdraw(uint256 amount) {
        require(amount <= investedAmount[msg.sender]);
        
        uint pendingReward = calculateReward(msg.sender);
        _updateInvestment(msg.sender, -amount);
        _updateLastCumulativeRatio(msg.sender);
        _updateCumulativeRatio(pendingReward, totalInvested);
        
        msg.sender.transfer(amount);
    }
    
    function claimRewards() {
        uint pendingReward = calculateReward(msg.sender);
        _updateInvestment(msg.sender, pendingReward);
        _updateLastCumulativeRatio(msg.sender);
    }
    
    function penalize(address participant) {
        require(now > registrationTime[participant] + 14 hours && investedAmount[participant] > 0);
        
        uint pendingReward = calculateReward(participant);
        uint penaltyAmount = investedAmount[participant] / PERCENT_DIVISOR;
        uint actualPenalty = _calculatePenalty(participant, penaltyAmount);
        
        _updateCumulativeRatio(penaltyAmount, totalInvested);
        _updateInvestment(participant, -actualPenalty);
        _updateLastCumulativeRatio(participant);
        registrationTime[participant] = now;
        _updateCumulativeRatio(pendingReward, totalInvested);
    }
    
    function _calculatePenalty(address participant, uint penaltyAmount) private returns (uint) {
        uint penalty = penaltyAmount - (((penaltyAmount * DIVISOR) / totalInvested) * investedAmount[participant]) / DIVISOR;
        return penalty;
    }
}
```