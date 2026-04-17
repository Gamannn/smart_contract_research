```solidity
pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    address public beneficiary;
    address public tokenReward;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    uint public minEtherPerPurchase;
    uint public maxEtherPerPurchase;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    bool public priceRateChanged = false;
    mapping(address => uint) public balanceOf;
    
    uint public constant PRICE_RATE_1 = 0.000385901 * 1 ether;
    uint public constant PRICE_RATE_2 = 0.000515185 * 1 ether;
    uint public constant DECIMALS = 1000000000000000000;
    uint public constant GOAL = 225 * 1 ether;
    uint public constant START_TIME = 1515196740;
    uint public constant END_TIME = 1518566340;
    
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary);
        _;
    }
    
    function Crowdsale() {
        beneficiary = 0x8f42914C201AcDd8a2769211C862222Ec56eea40;
        fundingGoal = GOAL;
        deadline = END_TIME;
        price = PRICE_RATE_1;
        minEtherPerPurchase = 0;
        maxEtherPerPurchase = 225 * 1 ether;
    }
    
    function safeDiv(uint a, uint b) internal pure returns (uint) {
        return a / b;
    }
    
    function safeMul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function kill() onlyBeneficiary public {
        selfdestruct(beneficiary);
    }
    
    function closeCrowdsale() onlyBeneficiary public {
        crowdsaleClosed = true;
    }
    
    function startCrowdsale() onlyBeneficiary public {
        crowdsaleClosed = false;
    }
    
    function withdraw(uint amount) onlyBeneficiary public {
        if (beneficiary.send(amount)) {
            FundTransfer(beneficiary, amount, false);
        }
    }
    
    function updatePrice(uint newPrice) onlyBeneficiary public {
        price = newPrice;
        priceRateChanged = true;
    }
    
    function () payable {
        require(crowdsaleClosed == false);
        
        if (priceRateChanged == false) {
            if (now < deadline) {
                price = PRICE_RATE_1;
            } else {
                price = PRICE_RATE_2;
            }
        }
        
        uint amount = msg.value;
        uint tokenAmount = safeMul(amount, DECIMALS);
        uint tokensToSend = safeDiv(tokenAmount, price);
        
        require(amount >= minEtherPerPurchase && amount <= maxEtherPerPurchase);
        
        balanceOf[msg.sender] += amount;
        FundTransfer(msg.sender, amount, true);
        tokenReward.transfer(msg.sender, tokensToSend);
        amountRaised += amount;
    }
}
```