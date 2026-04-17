```solidity
pragma solidity ^0.4.20;

interface Token {
    function transfer(address to, uint amount) returns (bool success);
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    uint public tokenDecimals;
    uint public minContribution;
    uint public maxContribution;
    Token public tokenReward;
    
    mapping(address => uint256) public balanceOf;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    function Crowdsale(
        address ifSuccessfulSendTo,
        address addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        deadline = now + 120 days;
        price = 200000000000000;
        tokenDecimals = 18;
        minContribution = 0.01 ether;
        maxContribution = 10 ether;
        fundingGoal = 500 ether;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }
    
    function () payable {
        require(!crowdsaleClosed);
        require(msg.value >= minContribution);
        require(msg.value <= maxContribution);
        
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount * 10 ** tokenDecimals / price);
        FundTransfer(msg.sender, amount, true);
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
    
    function safeWithdrawal() afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }
        
        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
                amountRaised = 0;
            } else {
                fundingGoalReached = false;
            }
        }
    }
}
```