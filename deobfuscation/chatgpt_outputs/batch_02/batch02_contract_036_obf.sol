pragma solidity ^0.4.18;

contract Token {
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function balanceOf(address who) public constant returns (uint256 balance);
}

contract Crowdsale {
    address public owner;
    address public beneficiary;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    uint public startTime;
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    function Crowdsale(
        address ifSuccessfulSendTo,
        uint durationInMinutes,
        address addressOfTokenUsedAsReward,
        address addressOfBeneficiary
    ) public {
        owner = msg.sender;
        beneficiary = ifSuccessfulSendTo;
        deadline = now + durationInMinutes * 1 days;
        price = 1 ether / 1000;
        tokenReward = Token(addressOfTokenUsedAsReward);
        beneficiary = addressOfBeneficiary;
    }

    function getStage() public constant returns (uint stage) {
        require(now >= startTime);
        uint elapsed = now - startTime;
        uint stageDuration = deadline / 3;
        uint currentStage = 1 + elapsed / stageDuration;
        if (currentStage > 3) {
            currentStage = 3;
        }
        return currentStage;
    }

    function getPrice() public constant returns (uint pricePerToken) {
        uint basePrice = 1 ether / price / 2;
        uint stage = getStage();
        if (stage == 1) {
            return basePrice * 4;
        } else if (stage == 2) {
            return basePrice * 5;
        } else {
            return basePrice * 6;
        }
    }

    function () public payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transferFrom(beneficiary, msg.sender, amount / getPrice());
        FundTransfer(msg.sender, amount, true);
        checkGoalReached();
    }

    function checkGoalReached() public {
        uint256 tokenBalance = tokenReward.balanceOf(beneficiary);
        if (tokenBalance == 0) {
            fundingGoalReached = true;
            crowdsaleClosed = true;
            GoalReached(beneficiary, amountRaised);
        }
        if (now >= deadline) {
            crowdsaleClosed = true;
        }
    }

    function safeWithdrawal() public {
        if (beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            }
        }
    }

    function setPrice(uint _price) public {
        require(msg.sender == owner);
        price = _price;
    }
}