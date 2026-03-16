pragma solidity >=0.4.22 <0.6.0;

interface Token {
    function transfer(address recipient, uint amount) external;
}

contract Crowdsale {
    mapping(address => uint256) public contributions;
    
    event GoalReached(address beneficiary, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    struct Campaign {
        bool finalized;
        bool goalReached;
        uint deadline;
        uint amountRaised;
        uint fundingGoal;
        address beneficiary;
    }
    
    Campaign public campaign;
    
    constructor(
        address beneficiary,
        uint fundingGoalInEther,
        uint durationInMinutes
    ) public {
        campaign.beneficiary = beneficiary;
        campaign.fundingGoal = fundingGoalInEther * 1 ether;
        campaign.deadline = now + durationInMinutes * 1 minutes;
    }
    
    function () payable external {
        require(!campaign.finalized);
        uint amount = msg.value;
        contributions[msg.sender] += amount;
        campaign.amountRaised += amount;
        emit FundTransfer(msg.sender, amount, true);
    }
    
    modifier afterDeadline() {
        if (now >= campaign.deadline) _;
    }
    
    function checkGoalReached() public afterDeadline {
        if (campaign.amountRaised >= campaign.fundingGoal) {
            campaign.goalReached = true;
            emit GoalReached(campaign.beneficiary, campaign.amountRaised);
        }
        campaign.finalized = true;
    }
    
    function safeWithdrawal() public afterDeadline {
        if (!campaign.goalReached) {
            uint amount = contributions[msg.sender];
            contributions[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    emit FundTransfer(msg.sender, amount, false);
                } else {
                    contributions[msg.sender] = amount;
                }
            }
        }
        
        if (campaign.goalReached && campaign.beneficiary == msg.sender) {
            if (msg.sender.send(campaign.amountRaised)) {
                emit FundTransfer(campaign.beneficiary, campaign.amountRaised, false);
            } else {
                campaign.goalReached = false;
            }
        }
    }
}