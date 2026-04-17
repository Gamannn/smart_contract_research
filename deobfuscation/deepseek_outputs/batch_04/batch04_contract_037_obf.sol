```solidity
pragma solidity ^0.4.16;

interface Token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public deadline;
    uint public price;
    uint public initialTokenAmount;
    uint public currentTokenAmount;
    Token public tokenReward;
    
    mapping(address => uint256) public balanceOf;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        address addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = 13370000000000;
        initialTokenAmount = 747943160;
        currentTokenAmount = initialTokenAmount;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }
    
    function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        if (amount > 0) {
            balanceOf[msg.sender] += amount;
            currentBalance += amount;
            amountRaised += amount;
            uint tokenAmount = amount / price;
            currentTokenAmount -= tokenAmount;
            tokenReward.transfer(msg.sender, tokenAmount * 1 ether);
        }
    }
    
    function safeWithdrawal() public {
        if (beneficiary == msg.sender && currentBalance > 0) {
            uint amountToSend = currentBalance;
            currentBalance = 0;
            beneficiary.send(amountToSend);
        }
    }
    
    function withdrawUnsoldTokens() public {
        if (beneficiary == msg.sender && currentTokenAmount > 0) {
            tokenReward.transfer(beneficiary, currentTokenAmount);
        }
    }
    
    function returnUnsoldSafe() public {
        if (beneficiary == msg.sender) {
            uint tokenAmount = currentTokenAmount;
            tokenReward.transfer(beneficiary, tokenAmount);
        }
    }
    
    modifier afterDeadline() {
        if (now >= deadline) _;
    }
    
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }
    
    uint public amountRaised;
    uint public currentBalance;
}
```