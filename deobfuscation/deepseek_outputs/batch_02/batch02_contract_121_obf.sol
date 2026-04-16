pragma solidity ^0.4.11;

interface Token {
    function transfer(address receiver, uint256 amount);
    function transferFrom(address from, address to, uint256 amount);
    function balanceOf(address holder) constant returns(uint256 balance);
    function approve(address spender, uint256 amount);
    function allowance(address owner, address spender) constant returns(uint256 remaining);
}

contract Crowdsale {
    string public name = "CONTRACT DICEYBIT.COM preICO";
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    uint256 public tokensLeft;
    mapping(address => uint256) public balanceOf;
    bool public fundingGoalReached;
    bool public crowdsaleClosed;
    
    Token public tokenReward;
    
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    function Crowdsale(
        address ifSuccessfulSendTo,
        Token addressOfTokenUsedAsReward,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken
    ) {
        beneficiary = ifSuccessfulSendTo;
        tokenReward = Token(addressOfTokenUsedAsReward);
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken;
        tokensLeft = tokenReward.balanceOf(address(this));
    }
    
    function () payable {
        require(!crowdsaleClosed);
        require(tokensLeft >= msg.value / price);
        
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokensLeft -= amount / price;
        tokenReward.transfer(msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true);
        
        tokensLeft = tokenReward.balanceOf(address(this));
        if (tokensLeft == 0) {
            crowdsaleClosed = true;
        }
    }
    
    function updateTokensLeft() {
        tokensLeft = tokenReward.balanceOf(address(this));
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
            }
        }
    }
    
    function withdrawRemainingTokens() {
        require(tokensLeft > 0);
        if (msg.sender == beneficiary) {
            tokenReward.transfer(beneficiary, tokensLeft);
            tokensLeft = tokenReward.balanceOf(address(this));
        }
    }
}