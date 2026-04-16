```solidity
pragma solidity ^0.4.11;

interface Token {
    function transfer(address to, uint256 value);
    function transferFrom(address from, address to, uint256 value);
    function balanceOf(address who) constant returns(uint256);
    function allowance(address owner, address spender) constant returns(uint256);
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
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    Token public tokenReward;
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    function Crowdsale(
        address ifSuccessfulSendTo,
        Token addressOfTokenUsedAsReward,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken
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
        tokensLeft = tokenReward.balanceOf(address(this));
        uint tokenAmount = amount / price;
        tokenReward.transfer(msg.sender, tokenAmount);
        FundTransfer(msg.sender, amount, true);
        if (tokensLeft == 0) {
            crowdsaleClosed = true;
        }
    }

    function checkGoalReached() {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
            crowdsaleClosed = true;
        }
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

    modifier afterDeadline() {
        if (now >= deadline) _;
    }
}
```