pragma solidity ^0.4.20;

interface Token {
    function transfer(address to, uint256 value) returns (bool success);
}

contract Crowdsale {
    address public beneficiary;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    uint public softCap;
    uint public hardCap;
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public softCapReached = false;
    bool public crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    function Crowdsale(
        address ifSuccessfulSendTo,
        address addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        softCap = 500 ether;
        hardCap = 3200 ether;
        deadline = now + 120 days;
        tokenReward = Token(addressOfTokenUsedAsReward);
        price = 200000000000000;
    }

    function () payable {
        require(!crowdsaleClosed);
        require(amountRaised + msg.value <= hardCap);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount * 10 ** uint256(18) / price);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() {
        if (now >= deadline) _;
    }

    function checkGoalReached() afterDeadline {
        if (amountRaised >= softCap) {
            softCapReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    function safeWithdrawal() afterDeadline {
        if (!softCapReached) {
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

        if (softCapReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                softCapReached = false;
            }
        }
    }
}