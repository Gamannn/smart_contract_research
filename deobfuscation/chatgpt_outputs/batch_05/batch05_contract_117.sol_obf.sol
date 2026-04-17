pragma solidity ^0.4.18;

interface TokenInterface {
    function transfer(address to, uint tokens) external;
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    TokenInterface public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    constructor() public {
        beneficiary = 0xb2769a802438C39f01C700D718Aea13754C7D378;
        fundingGoal = 8000 ether;
        deadline = now + 30 days;
        price = 213000000000000 wei;
        tokenReward = TokenInterface(0x66d544B100966F99A72734c7eB471fB9556BadFd);
    }

    function () payable public {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        uint tokenAmount = amount / price * 1 ether;
        tokenReward.transfer(msg.sender, tokenAmount);
        emit FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() {
        if (now >= deadline) _;
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