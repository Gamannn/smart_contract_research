pragma solidity ^0.4.11;

contract Token {
    function transfer(address to, uint amount) public {}
}

contract Crowdsale {
    Token public tokenReward;
    mapping(address => uint256) public contributions;
    
    event GoalReached(address recipient, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    struct CrowdsaleState {
        bool crowdsaleClosed;
        bool fundingGoalReached;
        uint256 price;
        uint256 deadline;
        uint256 amountRaised;
        uint256 fundingGoal;
        address beneficiary;
    }
    
    CrowdsaleState public state;
    
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        Token addressOfTokenUsedAsReward
    ) public {
        state.beneficiary = ifSuccessfulSendTo;
        state.fundingGoal = fundingGoalInEthers * 1 ether;
        state.deadline = now + durationInMinutes * 1 minutes;
        state.price = etherCostOfEachToken * 1 wei;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }
    
    function () public payable {
        require(!state.crowdsaleClosed);
        uint amount = msg.value;
        contributions[msg.sender] += amount;
        state.amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / state.price);
        FundTransfer(msg.sender, amount, true);
    }
    
    modifier afterDeadline() {
        require(now >= state.deadline);
        _;
    }
    
    function checkGoalReached() public afterDeadline {
        if (state.amountRaised >= state.fundingGoal && !state.fundingGoalReached) {
            state.fundingGoalReached = true;
            GoalReached(state.beneficiary, state.amountRaised);
        }
        state.crowdsaleClosed = true;
    }
    
    function safeWithdrawal() public afterDeadline {
        checkGoalReached();
        
        if (!state.fundingGoalReached) {
            uint amount = contributions[msg.sender];
            contributions[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    contributions[msg.sender] = amount;
                }
            }
        }
        
        if (state.fundingGoalReached && state.beneficiary == msg.sender) {
            if (state.beneficiary.send(state.amountRaised)) {
                FundTransfer(state.beneficiary, state.amountRaised, false);
            } else {
                state.fundingGoalReached = false;
            }
        }
    }
    
    function tokenWithdraw(uint256 amount) public afterDeadline {
        require(state.beneficiary == msg.sender);
        tokenReward.transfer(msg.sender, amount);
    }
}