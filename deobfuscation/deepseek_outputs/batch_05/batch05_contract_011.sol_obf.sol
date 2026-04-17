```solidity
pragma solidity ^0.4.13;

library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint a, uint b) internal returns (uint) {
        uint c = a / b;
        return c;
    }
    
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
    
    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }
    
    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }
    
    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }
    
    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

interface Token {
    function transfer(address receiver, uint amount);
    function balanceOf(address) returns (uint256);
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    uint public tokenBalance;
    
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    function Crowdsale() {
        tokenBalance = 49893;
        beneficiary = 0x6519C9A1BF6d69a35C7C87435940B05e9915Ccb3;
        tokenReward = Token(0xb957B54c347342893b7d79abE2AaF543F7598531);
        deadline = now + 30 * 1 days;
        price = 475;
        fundingGoal = 0;
    }
    
    function () payable {
        uint amount = msg.value;
        uint tokenAmount;
        
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        
        if (now <= now + 7 days) {
            tokenAmount = SafeMath.div(amount, price);
        } else {
            tokenAmount = SafeMath.div(3 * 1 ether, price);
        }
        
        tokenBalance = SafeMath.sub(tokenBalance, SafeMath.div(amount, price));
        
        if (tokenBalance < 0) {
            revert();
        }
        
        tokenReward.transfer(msg.sender, SafeMath.div(amount, tokenAmount));
        FundTransfer(msg.sender, amount, true);
    }
    
    modifier afterDeadline() {
        if (now >= deadline) _;
    }
    
    modifier beforeDeadline() {
        if (now <= deadline) _;
    }
    
    function safeWithdrawal() afterDeadline {
        if (beneficiary.send(amountRaised)) {
            FundTransfer(beneficiary, amountRaised, false);
            tokenReward.transfer(beneficiary, tokenReward.balanceOf(this));
            amountRaised = 0;
        }
    }
}
```