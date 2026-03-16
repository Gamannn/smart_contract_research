pragma solidity ^0.4.18;

interface Token {
    function transfer(address receiver, address sender, uint256 amount) public;
}

contract Crowdsale {
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    
    event GoalReached(address beneficiary, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event CrowdsaleClose(uint totalAmountRaised, bool goalReached);
    
    struct Campaign {
        bool crowdsaleClosed;
        bool goalReached;
        uint256 tokenPrice;
        uint256 deadline;
        uint256 startTime;
        uint256 amountRaised;
        uint256 fundingGoal;
        address beneficiary;
    }
    
    Campaign public campaign = Campaign(
        false,
        false,
        0,
        0,
        0,
        0,
        0,
        address(0)
    );
    
    function Crowdsale(
        address beneficiary,
        uint fundingGoalInEthers,
        uint startTime,
        uint durationInMinutes,
        uint tokenPriceInFinney,
        address addressOfTokenUsedAsReward
    ) public {
        campaign.beneficiary = beneficiary;
        campaign.fundingGoal = fundingGoalInEthers * 1 ether;
        campaign.startTime = startTime;
        campaign.deadline = startTime + durationInMinutes * 1 minutes;
        campaign.tokenPrice = tokenPriceInFinney * 1 finney;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }
    
    function processTransaction() internal {
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        campaign.amountRaised += amount;
        
        tokenReward.transfer(
            campaign.beneficiary,
            msg.sender,
            (amount * campaign.tokenPrice) / 1 ether
        );
        
        checkGoalReached();
        FundTransfer(msg.sender, amount, true);
    }
    
    function () payable onlyDuringCrowdsale onlyIfNotClosed public {
        processTransaction();
    }
    
    function contribute() payable public returns(bool success) {
        processTransaction();
        return true;
    }
    
    modifier onlyAfterStart() {
        require(now >= campaign.startTime);
        _;
    }
    
    modifier onlyAfterDeadline() {
        require(now >= campaign.deadline);
        _;
    }
    
    modifier onlyDuringCrowdsale() {
        require(now <= campaign.deadline);
        _;
    }
    
    modifier onlyBeneficiary() {
        require(msg.sender == campaign.beneficiary);
        _;
    }
    
    modifier onlyIfClosed() {
        require(campaign.crowdsaleClosed);
        _;
    }
    
    modifier onlyIfNotClosed() {
        require(!campaign.crowdsaleClosed);
        _;
    }
    
    function checkGoalReached() internal {
        if (campaign.amountRaised >= campaign.fundingGoal && !campaign.goalReached) {
            campaign.goalReached = true;
            GoalReached(campaign.beneficiary, campaign.amountRaised);
        }
    }
    
    function closeCrowdsale() onlyBeneficiary public {
        campaign.crowdsaleClosed = true;
        CrowdsaleClose(campaign.amountRaised, campaign.goalReached);
    }
    
    function safeWithdrawal() onlyAfterDeadline onlyIfClosed public {
        if (!campaign.goalReached) {
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
        
        if (campaign.goalReached && campaign.beneficiary == msg.sender) {
            if (campaign.beneficiary.send(campaign.amountRaised)) {
                FundTransfer(campaign.beneficiary, campaign.amountRaised, false);
            } else {
                campaign.goalReached = false;
            }
        }
    }
}