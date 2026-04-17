```solidity
pragma solidity ^0.4.0;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        if (a == 0) {
            return 0;
        } else {
            uint c = a * b;
            require(c / a == b);
            return c;
        }
    }
    
    function safeDiv(uint a, uint b) internal returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }
}

contract Token {
    function balanceOf(address owner) constant returns (uint balance);
    function transfer(address to, uint amount) returns (bool success);
}

contract TokenExchange is SafeMath {
    uint public priceInWei;
    bool public exchangeActive = false;
    uint public tokensPerEth = 100000000;
    
    address public creator;
    address public tokenAddress;
    
    event TokenTransfer(address indexed buyer, uint amount);
    event TokenExchangeFailed(address indexed buyer, uint amount);
    event EthFundTransfer(uint amount);
    event TokenFundTransfer(uint amount);
    
    function TokenExchange(uint initialPrice, address tokenAddr) {
        creator = msg.sender;
        priceInWei = initialPrice;
        tokenAddress = tokenAddr;
    }
    
    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }
    
    function setPrice(uint newPrice) onlyCreator() returns (bool success) {
        require(!exchangeActive);
        priceInWei = newPrice;
        return true;
    }
    
    function stopExchange() onlyCreator() returns (bool success) {
        exchangeActive = false;
        return true;
    }
    
    function startExchange() onlyCreator() returns (bool success) {
        exchangeActive = true;
        return true;
    }
    
    function () payable {
        require(exchangeActive);
        uint ethAmount = msg.value;
        uint tokens = safeDiv(safeMul(ethAmount, tokensPerEth), priceInWei);
        
        if (tokens <= Token(tokenAddress).balanceOf(this)) {
            Token(tokenAddress).transfer(msg.sender, tokens);
            TokenTransfer(msg.sender, tokens);
        } else {
            TokenExchangeFailed(msg.sender, tokens);
            revert();
        }
    }
    
    function withdrawEth() onlyCreator() returns (bool success) {
        require(!exchangeActive);
        if (creator.send(this.balance)) {
            EthFundTransfer(this.balance);
            return true;
        }
        return false;
    }
    
    function withdrawTokens() onlyCreator() returns (bool success) {
        require(!exchangeActive);
        Token token = Token(tokenAddress);
        if (token.transfer(creator, token.balanceOf(this))) {
            TokenFundTransfer(token.balanceOf(this));
            return true;
        }
        return false;
    }
    
    function destroy() public onlyCreator() {
        require(!exchangeActive);
        selfdestruct(msg.sender);
    }
}
```