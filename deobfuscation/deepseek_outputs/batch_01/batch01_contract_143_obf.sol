pragma solidity ^0.4.11;

contract token {
    function transfer(address, uint) {}
}

contract CrowdsaleWatch {
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    struct Campaign {
        bool crowdsaleClosed;
        bool fundingGoalReached;
        uint256 price;
        uint256 deadline;
        uint256 amountRaised;
        uint256 fundingGoal;
        address beneficiary;
    }
    
    Campaign public campaign;
    
    function CrowdsaleWatch(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        token addressOfTokenUsedAsReward
    ) {
        campaign.beneficiary = ifSuccessfulSendTo;
        campaign.fundingGoal = fundingGoalInEthers * 5000 ether;
        campaign.deadline = now + durationInMinutes * 1 minutes;
        campaign.price = etherCostOfEachToken * 5000000 wei;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
    function () payable {
        if (campaign.crowdsaleClosed) throw;
        uint amount = msg.value;
        balanceOf[msg.sender] = amount;
        campaign.amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / campaign.price);
        FundTransfer(msg.sender, amount, true);
    }
    
    modifier afterDeadline() {
        if (now >= campaign.deadline) _;
    }
    
    function checkGoalReached() afterDeadline {
        if (campaign.amountRaised >= campaign.fundingGoal && !campaign.fundingGoalReached) {
            campaign.fundingGoalReached = true;
            GoalReached(campaign.beneficiary, campaign.amountRaised);
        }
        campaign.crowdsaleClosed = true;
    }
    
    function safeWithdrawal() afterDeadline {
        checkGoalReached();
        
        if (!campaign.fundingGoalReached) {
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
        
        if (campaign.fundingGoalReached && campaign.beneficiary == msg.sender) {
            if (campaign.beneficiary.send(campaign.amountRaised)) {
                FundTransfer(campaign.beneficiary, campaign.amountRaised, false);
            } else {
                campaign.fundingGoalReached = false;
            }
        }
    }
    
    function tokenWithdraw(uint256 amount) afterDeadline {
        if (campaign.beneficiary == msg.sender) {
            tokenReward.transfer(msg.sender, amount);
        }
    }
}