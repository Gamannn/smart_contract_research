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
    uint public amountRaised;
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
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }
    
    function () payable {
        require(!crowdsaleClosed);
        
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        
        if(amount > 10 ether) {
            tokenReward.transfer(msg.sender, (amount / price) + ((amount / price)/2) + ((amount / price)/20));
        } else {
            tokenReward.transfer(msg.sender, (amount / price) + ((amount / price)/2));
        }
        
        FundTransfer(msg.sender, amount, true);
    }
    
    function kill() public {
        if(msg.sender == beneficiary) {
            selfdestruct(beneficiary);
        }
    }
    
    modifier afterDeadline() {
        require(now >= deadline);
        _;
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
            } else {
                fundingGoalReached = false;
            }
        }
    }
}
```