```solidity
pragma solidity ^0.4.19;

contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

interface Token {
    function transfer(address to, uint tokens) public returns (bool success);
}

interface PricingStrategy {
    function calculateTokenAmount(uint weiAmount, uint tokensSold) public returns (uint tokenAmount, uint weiLeft);
}

contract Crowdsale is SafeMath {
    address internal owner;
    address internal wallet;
    uint internal fundingGoal;
    uint internal amountRaised;
    bool internal fundingGoalReached;
    bool internal crowdsaleClosed;
    bool internal unlockFundersBalance;
    mapping(address => uint) internal balanceOf;
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    function Crowdsale() public {
        owner = msg.sender;
        wallet = owner;
        fundingGoalReached = false;
        crowdsaleClosed = false;
        unlockFundersBalance = false;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setWallet(address newWallet) public onlyOwner {
        wallet = newWallet;
    }

    function setFundingGoal(uint newFundingGoal) public onlyOwner {
        fundingGoal = newFundingGoal;
    }

    function closeCrowdsale() public onlyOwner {
        crowdsaleClosed = true;
    }

    function openCrowdsale() public onlyOwner {
        crowdsaleClosed = false;
    }

    function () payable public {
        require(!crowdsaleClosed && unlockFundersBalance);
        uint amount = msg.value;
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], amount);
        amountRaised = safeAdd(amountRaised, amount);
        FundTransfer(msg.sender, amount, true);
    }

    function checkGoalReached() public {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(wallet, amountRaised);
            crowdsaleClosed = true;
        }
    }

    function safeWithdrawal() public {
        if (!fundingGoalReached || unlockFundersBalance) {
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
    }

    function withdrawFunds(uint amount) public onlyOwner returns (bool success) {
        if (fundingGoalReached && wallet == msg.sender && !unlockFundersBalance) {
            if (wallet.send(amount)) {
                amountRaised = safeSub(amountRaised, amount);
                return true;
            }
        }
        return false;
    }
}
```