pragma solidity ^0.4.16;

interface TokenReward {
    function transfer(address to, uint amount);
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    TokenReward public rewardToken;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
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
        rewardToken = TokenReward(addressOfTokenUsedAsReward);
    }

    function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        if (amount > 10 ether) {
            rewardToken.transfer(msg.sender, (amount / price) + ((amount / price) / 2) + ((amount / price) / price));
        } else {
            rewardToken.transfer(msg.sender, (amount / price) + ((amount / price) / 2));
        }
        FundTransfer(msg.sender, amount, true);
    }

    function checkGoalReached() public {
        if (now >= deadline) {
            if (amountRaised >= fundingGoal) {
                fundingGoalReached = true;
                GoalReached(beneficiary, amountRaised);
            }
            crowdsaleClosed = true;
        }
    }

    function safeWithdrawal() public {
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