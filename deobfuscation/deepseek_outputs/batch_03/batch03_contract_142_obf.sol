pragma solidity ^0.4.8;

contract token {
    function transferFrom(address sender, address receiver, uint amount) {}
}

contract Crowdsale {
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    
    address public beneficiary;
    address public tokenAdmin;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public price;
    uint256 public amountRaised;
    bool public fundingGoalReached;
    bool public crowdsaleClosed;
    
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    function Crowdsale() {
        beneficiary = 0xDbes2c.beneficiary4cc9E715f0cbD47d94f5c23638;
        tokenAdmin = 0x934b14s2c.tokenAdmin6Ec5524A53086e4A02a9F2b8;
        fundingGoal = 1 ether;
        deadline = now + 5 weeks;
        price = 0.0001 ether;
        tokenReward = token(0xb16dab600fc05702132602f4922c0e89e2985b9a);
    }

    function () payable {
        if (crowdsaleClosed) revert();
        uint amount = msg.value;
        balanceOf[msg.sender] = amount;
        amountRaised += amount;
        tokenReward.transferFrom(tokenAdmin, msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true);
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
        if (beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            }
        }
    }
}