pragma solidity ^0.4.18;

interface Token {
    function transfer(address from, address to, uint256 value) public;
}

contract Crowdsale {
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event CrowdsaleClose(uint totalAmountRaised, bool goalReached);

    struct CrowdsaleData {
        bool crowdsaleClosed;
        bool goalReached;
        uint256 price;
        uint256 deadline;
        uint256 startTime;
        uint256 amountRaised;
        uint256 fundingGoal;
        address beneficiary;
    }

    CrowdsaleData public crowdsaleData;

    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint startAfterMinutes,
        uint etherCostOfEachTokenInFinney,
        address addressOfTokenUsedAsReward
    ) public {
        crowdsaleData.beneficiary = ifSuccessfulSendTo;
        crowdsaleData.fundingGoal = fundingGoalInEthers * 1 ether;
        crowdsaleData.startTime = now + startAfterMinutes * 1 minutes;
        crowdsaleData.deadline = crowdsaleData.startTime + durationInMinutes * 1 minutes;
        crowdsaleData.price = etherCostOfEachTokenInFinney * 1 finney;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }

    function contribute() internal {
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        crowdsaleData.amountRaised += amount;
        tokenReward.transfer(crowdsaleData.beneficiary, msg.sender, (amount * crowdsaleData.price) / 1 ether);
        checkGoalReached();
        FundTransfer(msg.sender, amount, true);
    }

    function() payable public {
        require(now >= crowdsaleData.startTime && now <= crowdsaleData.deadline && !crowdsaleData.crowdsaleClosed);
        contribute();
    }

    function contributeManually() payable public returns(bool success) {
        require(now >= crowdsaleData.startTime && now <= crowdsaleData.deadline && !crowdsaleData.crowdsaleClosed);
        contribute();
        return true;
    }

    modifier afterDeadline() {
        require(now >= crowdsaleData.deadline);
        _;
    }

    modifier onlyBeneficiary() {
        require(msg.sender == crowdsaleData.beneficiary);
        _;
    }

    modifier goalNotReached() {
        require(!crowdsaleData.goalReached);
        _;
    }

    modifier goalReached() {
        require(crowdsaleData.goalReached);
        _;
    }

    function checkGoalReached() internal {
        if (crowdsaleData.amountRaised >= crowdsaleData.fundingGoal && !crowdsaleData.goalReached) {
            crowdsaleData.goalReached = true;
            GoalReached(crowdsaleData.beneficiary, crowdsaleData.amountRaised);
        }
    }

    function closeCrowdsale() onlyBeneficiary public {
        crowdsaleData.crowdsaleClosed = true;
        CrowdsaleClose(crowdsaleData.amountRaised, crowdsaleData.goalReached);
    }

    function safeWithdrawal() afterDeadline goalNotReached public {
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

    function withdrawFunds() afterDeadline goalReached onlyBeneficiary public {
        if (crowdsaleData.beneficiary.send(crowdsaleData.amountRaised)) {
            FundTransfer(crowdsaleData.beneficiary, crowdsaleData.amountRaised, false);
        } else {
            crowdsaleData.goalReached = false;
        }
    }
}