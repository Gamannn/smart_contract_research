```solidity
pragma solidity ^0.4.15;

contract Token {
    function transfer(address to, uint amount) public;
}

contract Crowdsale {
    Token public token;
    
    event SaleStageUp(int stage, uint price);
    
    address public beneficiary;
    uint public decimals;
    uint public totalAmount;
    
    uint public priceInWei;
    uint public availableTokensOnCurrentStage;
    int public currentStage;
    
    function Crowdsale() public {
        beneficiary = msg.sender;
        decimals = 100;
        priceInWei = 1000 * (10 ** decimals);
        token = Token(0xD7a1BF3Cc676Fc7111cAD65972C8499c9B98Fb6f);
        availableTokensOnCurrentStage = 0;
        currentStage = -3;
    }
    
    function buyTokens() public payable {
        uint amount = msg.value;
        
        if (amount < 1 finney) revert();
        
        uint tokens = amount * priceInWei / (10 ** decimals);
        
        if (tokens > availableTokensOnCurrentStage) revert();
        if (currentStage > 21) revert();
        
        totalAmount += amount;
        availableTokensOnCurrentStage -= tokens;
        
        if (totalAmount >= 1 ether && currentStage == -3) {
            currentStage = -2;
            priceInWei = 1000 * (10 ** decimals);
            SaleStageUp(currentStage, priceInWei);
        }
        
        if (currentStage == -2 && totalAmount >= 3 ether) {
            currentStage = -1;
            priceInWei = 1000 * (10 ** decimals);
            SaleStageUp(currentStage, priceInWei);
        }
        
        if (currentStage == -1 && totalAmount >= 10 ether) {
            currentStage = 0;
            priceInWei = 1000 * (10 ** decimals);
            availableTokensOnCurrentStage = 2100000;
            SaleStageUp(currentStage, priceInWei);
        }
        
        token.transfer(msg.sender, tokens);
    }
    
    modifier onlyBeneficiary() {
        if (msg.sender != beneficiary) revert();
        _;
    }
    
    function withdrawTokens(address tokenAddress, uint amount) public onlyBeneficiary {
        if (tokenAddress == address(0)) revert();
        Token(tokenAddress).transfer(beneficiary, amount);
    }
    
    function finalize() public onlyBeneficiary {
        if (currentStage > -1) revert();
        currentStage = 0;
        priceInWei = priceInWei * 2;
        availableTokensOnCurrentStage = 2100000;
        SaleStageUp(currentStage, priceInWei);
    }
}
```