pragma solidity >=0.4.25 <0.6.0;

interface TokenInterface {
    function transfer(address to, uint tokens) external;
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public deadline;
    uint public price;
    TokenInterface public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    uint public amountRaised;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event LogAmount(uint amount);

    constructor(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint costOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = costOfEachToken * 1 wei;
        tokenReward = TokenInterface(addressOfTokenUsedAsReward);
    }

    function contribute() public payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        emit LogAmount(amount);
        tokenReward.transfer(msg.sender, 2000 * (amount / price));
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

    function getBoolFunc(uint index) internal view returns (bool) {
        return _bool_constant[index];
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    bool[] public _bool_constant = [false, true];
    uint256[] public _integer_constant = [2000, 1, 60, 1000000000000000000];
}