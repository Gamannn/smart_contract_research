```solidity
pragma solidity ^0.4.18;

interface IERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract TokenReceiver {
    function tokenFallback(address from, uint256 amount, address to, bytes data) public;
}

contract TokenExchange is TokenReceiver {
    uint256 public constant MAGNITUDE = 100000000000000;
    uint256 public constant SELL_RATE = 50000000000000;
    
    IERC20 public token;
    address public owner;
    uint256 public contractTokenBalance;
    bool public tradingActive;
    
    event BoughtToken(uint256 tokensReceived, uint256 ethSent, address indexed buyer);
    event SoldToken(uint256 tokensSold, uint256 ethReceived, address indexed seller);
    
    constructor() public {
        owner = 0x96357e75B7Ccb1a7Cf10Ac6432021AEa7174c803;
        token = IERC20(owner);
        tradingActive = true;
    }
    
    function tokenFallback(address from, uint256 amount, address to, bytes data) public {
        require(tradingActive);
        require(msg.sender == owner);
        
        uint256 ethAmount = calculateTokenSell(amount);
        token.transfer(from, ethAmount);
        emit SoldToken(amount, ethAmount, from);
    }
    
    function buyTokens() public payable {
        require(tradingActive);
        
        uint256 tokensBought = calculateTokenBuy(
            msg.value,
            safeSubtract(token.balanceOf(this), msg.value)
        );
        
        token.transfer(msg.sender, tokensBought);
        emit BoughtToken(tokensBought, msg.value, msg.sender);
    }
    
    function calculateTrade(
        uint256 amount,
        uint256 marketSupply,
        uint256 contractBalance
    ) public view returns(uint256) {
        return safeDivide(
            safeMultiply(MAGNITUDE, contractBalance),
            safeAdd(
                SELL_RATE,
                safeDivide(
                    safeMultiply(
                        safeAdd(
                            safeMultiply(SELL_RATE, marketSupply),
                            SELL_RATE
                        ),
                        amount
                    ),
                    marketSupply
                )
            )
        );
    }
    
    function calculateTokenSell(uint256 tokensToSell) public view returns(uint256) {
        return calculateTrade(
            tokensToSell,
            token.balanceOf(this),
            this.balance
        );
    }
    
    function calculateTokenBuy(uint256 ethAmount, uint256 contractTokenBalance) public view returns(uint256) {
        return calculateTrade(
            ethAmount,
            contractTokenBalance,
            token.balanceOf(this)
        );
    }
    
    function calculateEthToTokens(uint256 ethAmount) public view returns(uint256) {
        return calculateTokenBuy(ethAmount, this.balance);
    }
    
    function() public payable {}
    
    function getContractBalance() public view returns(uint256) {
        return this.balance;
    }
    
    function getTokenBalance() public view returns(uint256) {
        return token.balanceOf(this);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {
    function multiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function divide(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
```