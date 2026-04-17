```solidity
pragma solidity ^0.4.18;

interface Token {
    function transfer(address receiver, uint amount) external;
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    uint public startDate;
    uint public priceTier1;
    uint public priceTier2;
    uint public priceTier3;
    uint public priceTier4;
    Token public tokenReward;
    
    mapping(address => uint256) public balanceOf;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    constructor() public {
        beneficiary = 0xb2769a802438C39f01C700D718Aea13754C7D378;
        fundingGoal = 8000 ether;
        uint durationInMinutes = 43200;
        uint weiCostOfEachToken = 213000000000000;
        address tokenAddress = 0x66d544B100966F99A72734c7eB471fB9556BadFd;
        
        tokenReward = Token(tokenAddress);
        startDate = now;
        deadline = now + durationInMinutes * 1 minutes;
        price = weiCostOfEachToken;
        
        priceTier1 = price + 12000000000000;
        priceTier2 = price + 4000000000000;
        priceTier3 = price + 24000000000000;
        priceTier4 = price + 26000000000000;
    }
    
    function () payable public {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        
        uint currentPrice;
        if (startDate + 7 days <= now) {
            currentPrice = priceTier4;
        } else if (startDate + 14 days <= now) {
            currentPrice = priceTier3;
        } else if (startDate + 90 days <= now) {
            currentPrice = priceTier2;
        } else {
            currentPrice = priceTier1;
        }
        
        tokenReward.transfer(msg.sender, amount / currentPrice * 1 ether);
        emit FundTransfer(msg.sender, amount, true);
    }
    
    modifier afterDeadline() {
        require(now >= deadline);
        _;
    }
    
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }
    
    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }
        
        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                fundingGoalReached = false;
            }
        }
    }
}
```