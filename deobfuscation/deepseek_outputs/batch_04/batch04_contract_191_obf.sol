pragma solidity ^0.4.19;

interface Token {
    function buyCoinAtToken(address buyer, uint value, address beneficiary) public returns(bool success, uint amount);
}

interface ICO {
    function getICOStats() public returns(uint tokensSold, uint icoBalance, uint icoEndTime);
}

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

contract Crowdsale is SafeMath {
    address public owner;
    address public beneficiary;
    
    uint public fundingGoal;
    uint public amountRaised;
    uint public amountWithdrawn;
    uint public deadline;
    
    mapping(address => uint) public balances;
    
    bool public fundingGoalReached;
    bool public crowdsaleClosed;
    bool public unlockFundersBalance;
    bool public isEndOk;
    bool public saleParamSet;
    
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event FundOrPaymentTransfer(address receiver, uint amount);
    
    function Crowdsale() public {
        owner = msg.sender;
        beneficiary = owner;
        saleParamSet = false;
        fundingGoalReached = false;
        crowdsaleClosed = false;
        unlockFundersBalance = false;
        isEndOk = false;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function setTokenAddress(address tokenAddress) public onlyOwner returns(bool success) {
        tokenAddr = tokenAddress;
        return true;
    }
    
    function setICOAddress(address icoAddress) public onlyOwner returns(bool success) {
        icoAddr = icoAddress;
        return true;
    }
    
    function getTokenAddress() internal returns(address tokenAddress) {
        return tokenAddr;
    }
    
    function getICOAddress() internal returns(address icoAddress) {
        return icoAddr;
    }
    
    function setFundingGoal(uint fundingGoalInEth, bool reset) public onlyOwner returns(bool success) {
        if(saleParamSet == false || reset == true) {
            fundingGoal = fundingGoalInEth;
            saleParamSet = true;
        }
        return true;
    }
    
    function setCrowdsaleParams(
        bool startSale,
        bool closeSale,
        bool setDeadline,
        uint deadlineInMinutes,
        bool resetAmountWithdrawnToZero
    ) public onlyOwner returns(bool success) {
        if(setDeadline == true) {
            deadline = now + deadlineInMinutes * 1 minutes;
        }
        if(startSale == true) {
            crowdsaleClosed = false;
            unlockFundersBalance = true;
        }
        if(resetAmountWithdrawnToZero == true) {
            amountWithdrawn = 0;
        }
        return true;
    }
    
    function getAllControls(bool show) view public onlyOwner returns(
        bool paramSet,
        bool unlock,
        bool closed,
        bool goalReached,
        bool isEndOkStatus
    ) {
        if(show == true) {
            return (saleParamSet, unlockFundersBalance, crowdsaleClosed, fundingGoalReached, isEndOk);
        }
    }
    
    function () payable public {
        if(msg.sender != owner) {
            require(crowdsaleClosed == false && unlockFundersBalance == true);
            Token token = Token(getTokenAddress());
            bool success;
            uint amount;
            (success, amount) = token.buyCoinAtToken(msg.sender, msg.value, this);
            require(success == true);
            if(amount > 0) {
                bool transferSuccess;
                transferSuccess = safeTransfer(msg.sender, amount);
                require(transferSuccess == true);
            }
            uint refund = safeSub(msg.value, amount);
            balances[msg.sender] = safeAdd(balances[msg.sender], refund);
            amountRaised = safeAdd(amountRaised, refund);
            FundTransfer(msg.sender, refund, true);
        }
    }
    
    function getStats(bool showInWei) public returns(
        uint fundingGoalDisplay,
        uint amountRaisedDisplay,
        uint amountWithdrawnDisplay,
        uint minutesLeft,
        uint tokensSold,
        bool goalReachedStatus
    ) {
        if(unlockFundersBalance == true) {
            if(deadline >= now) {
                minutesLeft = safeSub(deadline, now) / 60;
            }
            if(now > deadline) {
                minutesLeft = 0;
            }
            ICO ico = ICO(getICOAddress());
            uint icoBalance;
            uint icoEndTime;
            (tokensSold, icoBalance, icoEndTime) = ico.getICOStats();
            if(showInWei == false) {
                return (
                    safeDiv(fundingGoal, 10**18),
                    safeDiv(amountRaised, 10**18),
                    safeDiv(amountWithdrawn, 10**18),
                    minutesLeft,
                    tokensSold,
                    fundingGoalReached
                );
            }
            if(showInWei == true) {
                return (fundingGoal, amountRaised, amountWithdrawn, minutesLeft, tokensSold, fundingGoalReached);
            }
        }
        return (balances[msg.sender]);
    }
    
    modifier afterDeadline() {
        if (now >= deadline) _;
    }
    
    function checkGoalReached() afterDeadline public {
        if(crowdsaleClosed == false) {
            if (amountRaised >= fundingGoal) {
                fundingGoalReached = true;
                GoalReached(beneficiary, amountRaised);
                crowdsaleClosed = true;
            } else {
                fundingGoalReached = false;
            }
        }
    }
    
    function safeWithdrawal() public {
        if ((!fundingGoalReached || isEndOk == true) && msg.sender != owner) {
            uint amount = balances[msg.sender];
            balances[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                    amountWithdrawn = safeAdd(amountWithdrawn, amount);
                } else {
                    balances[msg.sender] = amount;
                }
            }
        }
    }
    
    function beneficiaryWithdraw(uint amount, bool withdrawAll) onlyOwner public returns(bool success) {
        if (fundingGoalReached && beneficiary == msg.sender && isEndOk == false) {
            if(withdrawAll == true) {
                amount = safeSub(amountRaised, amountWithdrawn);
            }
            require(this.balance >= amount);
            amountWithdrawn = safeAdd(amountWithdrawn, amount);
            success = beneficiaryTransfer(amount);
            require(success == true);
            return success;
        }
    }
    
    function beneficiaryTransfer(uint amount) internal returns(bool success) {
        bool transferSuccess = safeTransfer(beneficiary, amount);
        require(transferSuccess == true);
        return true;
    }
    
    function safeTransfer(address receiver, uint amount) internal returns(bool success) {
        uint amountToSend = amount;
        uint checkAmount = amountToSend;
        amountToSend = 0;
        receiver.transfer(checkAmount);
        FundOrPaymentTransfer(receiver, checkAmount);
        checkAmount = 0;
        return true;
    }
    
    function setIsEndOk(bool status) public onlyOwner {
        isEndOk = status;
    }
    
    address private tokenAddr;
    address private icoAddr;
}