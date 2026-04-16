pragma solidity ^0.4.18;

interface Token {
    function transfer(address to, uint256 value) public returns (bool success);
    function balanceOf(address owner) public constant returns (uint256 balance);
}

contract Crowdsale {
    address public owner;
    address public beneficiary;
    address public wallet;
    uint256 public deadline;
    uint256 public periodDuration;
    uint256 public amountRaised;
    uint256 public etherCost;
    uint256 public startTime;
    Token public tokenReward;

    mapping(address => uint256) public balanceOf;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;

    event GoalReached(address beneficiary, uint256 amountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);

    function Crowdsale(
        address _beneficiary,
        uint256 _durationInDays,
        address _addressOfTokenUsedAsReward,
        address _wallet
    ) public {
        owner = msg.sender;
        beneficiary = _beneficiary;
        startTime = now;
        deadline = now + _durationInDays * 1 days;
        periodDuration = _durationInDays * 1 days / 3;
        tokenReward = Token(_addressOfTokenUsedAsReward);
        wallet = _wallet;
    }

    function stageNumber() public constant returns (uint256 stage) {
        require(now >= startTime);
        uint256 tempStage = 1 + (now - startTime) / periodDuration;
        if (tempStage > 3) {
            tempStage = 3;
        }
        stage = tempStage;
    }

    function tokenPerEther() public constant returns (uint256 tokens) {
        uint256 baseRate = 1 ether / etherCost / 2;
        uint256 stage = stageNumber();
        if (stage == 1) {
            tokens = baseRate * 4;
        } else if (stage == 2) {
            tokens = baseRate * 5;
        } else {
            tokens = baseRate * 6;
        }
    }

    function () public payable {
        require(!crowdsaleClosed);
        balanceOf[msg.sender] += msg.value;
        amountRaised += msg.value;
        tokenReward.transfer(msg.sender, msg.value * tokenPerEther());
        FundTransfer(msg.sender, msg.value, true);
        checkGoalReached();
    }

    function checkGoalReached() public {
        uint256 walletBalance = tokenReward.balanceOf(wallet);
        if (walletBalance == 0) {
            fundingGoalReached = true;
            crowdsaleClosed = true;
            GoalReached(beneficiary, amountRaised);
        }
        if (now >= deadline) {
            crowdsaleClosed = true;
        }
    }

    function safeWithdrawal() public {
        require(crowdsaleClosed);
        require(msg.sender == owner);
        if (beneficiary.send(amountRaised)) {
            FundTransfer(beneficiary, amountRaised, false);
        }
    }

    function setEtherCost(uint256 _etherCost) public {
        require(msg.sender == owner);
        etherCost = _etherCost;
    }
}