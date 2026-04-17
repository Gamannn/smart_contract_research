pragma solidity >=0.4.25 <0.6.0;

interface Token {
    function transfer(address receiver, uint amount) external;
}

contract Crowdsale {
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    
    address public beneficiary;
    uint public fundingGoal;
    uint public deadline;
    uint public price;
    uint public amountRaised;
    
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event LogAmount(uint amount);
    
    constructor(
        address tokenAddress,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address beneficiaryWallet
    ) public {
        beneficiary = beneficiaryWallet;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 wei;
        tokenReward = Token(tokenAddress);
    }
    
    function () external payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        LogAmount(amount);
        tokenReward.transfer(msg.sender, 2000 * (amount / price));
        FundTransfer(msg.sender, amount, true);
    }
    
    modifier afterDeadline() {
        if (now >= deadline) _;
    }
    
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }
    
    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                FundTransfer(msg.sender, amount, false);
            }
        }
        
        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                fundingGoalReached = false;
            }
        }
    }
}