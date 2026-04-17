pragma solidity ^0.4.16;

interface TokenInterface {
    function transfer(address to, uint tokens) external;
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public deadline;
    uint public price;
    uint public initialTokenAmount;
    uint public currentTokenAmount;
    TokenInterface public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    event GoalReached(address recipient, uint totalAmountRaised);

    struct CrowdsaleState {
        bool fundingGoalReached;
        bool crowdsaleClosed;
        uint256 amountRaised;
        uint256 currentBalance;
        uint256 price;
        uint256 deadline;
        uint256 totalRaised;
        uint256 fundingGoal;
        address beneficiary;
    }

    CrowdsaleState state;

    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = 13370000000000;
        initialTokenAmount = 747943160;
        currentTokenAmount = initialTokenAmount;
        tokenReward = TokenInterface(addressOfTokenUsedAsReward);
    }

    function () public payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        if (amount > 0) {
            balanceOf[msg.sender] += amount;
            state.amountRaised += amount;
            state.totalRaised += amount;
            uint tokens = amount / price;
            currentTokenAmount -= tokens;
            tokenReward.transfer(msg.sender, tokens * 1 ether);
        }
    }

    function checkGoalReached() public {
        if (state.amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, state.amountRaised);
        }
        crowdsaleClosed = true;
    }

    function safeWithdrawal() public {
        if (beneficiary == msg.sender && state.totalRaised > 0) {
            uint amountToWithdraw = state.totalRaised;
            state.totalRaised = 0;
            beneficiary.send(amountToWithdraw);
        }
    }

    function withdrawUnsoldTokens() public {
        if (beneficiary == msg.sender) {
            tokenReward.transfer(beneficiary, currentTokenAmount);
        }
    }

    function returnUnsoldTokens() public {
        if (beneficiary == msg.sender) {
            tokenReward.transfer(beneficiary, currentTokenAmount);
        }
    }

    modifier afterDeadline() {
        if (now >= deadline) _;
    }

    bool[] public _bool_constant = [false, true];
    uint256[] public _integer_constant = [1000000000000000000, 747943160, 60, 100000, 0, 13370000000000];

    function getBoolFunc(uint256 index) internal view returns(bool) {
        return _bool_constant[index];
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
}