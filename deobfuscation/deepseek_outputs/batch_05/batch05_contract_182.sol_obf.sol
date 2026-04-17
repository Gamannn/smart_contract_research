```solidity
pragma solidity ^0.4.23;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract TokenExchange is Ownable {
    using SafeMath for uint256;
    
    uint256 public buyPrice;
    uint256 public sellPrice;
    address public tokenAddress;
    
    uint256 private constant DECIMALS = 10**18;
    uint256 private constant PERCENT_DENOMINATOR = 100;
    uint256 private constant SELL_PRICE_DEFAULT = 300;
    
    constructor() public {
        buyPrice = 360 * DECIMALS;
        sellPrice = SELL_PRICE_DEFAULT * DECIMALS;
        tokenAddress = 0xeDc2f2077252c2E9B5CB5b5713CC74A071A4d298;
    }
    
    function setBuyPrice(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }
    
    function setSellPrice(uint256 newSellPrice) onlyOwner public {
        sellPrice = newSellPrice;
    }
    
    function sellTokens() payable public {
        sellTokensInternal();
    }
    
    function sellTokensInternal() payable public {
        ERC20 token = ERC20(tokenAddress);
        uint256 tokensToSell = msg.value.mul(sellPrice);
        tokensToSell = tokensToSell.div(DECIMALS);
        
        require(token.balanceOf(address(this)) >= tokensToSell);
        require(token.transfer(msg.sender, tokensToSell));
        
        emit SellTransaction(msg.value, tokensToSell);
    }
    
    function buyTokens(uint256 tokenAmount) public {
        address buyer = msg.sender;
        ERC20 token = ERC20(tokenAddress);
        
        uint256 transactionPrice = tokenAmount.div(buyPrice);
        transactionPrice = transactionPrice.mul(DECIMALS);
        transactionPrice = transactionPrice.mul(PERCENT_DENOMINATOR);
        
        require(address(this).balance >= transactionPrice);
        require(token.transferFrom(msg.sender, address(this), tokenAmount));
        
        buyer.transfer(transactionPrice);
        
        emit BuyTransaction(transactionPrice, tokenAmount);
    }
    
    function withdrawEther(uint256 amount) onlyOwner public {
        msg.sender.transfer(amount);
    }
    
    function withdrawTokens(uint256 amount) onlyOwner public {
        ERC20 token = ERC20(tokenAddress);
        token.transfer(msg.sender, amount);
    }
    
    function destroyContract() onlyOwner public {
        ERC20 token = ERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        
        if (tokenBalance > 0) {
            token.transfer(msg.sender, tokenBalance);
        }
        
        msg.sender.transfer(address(this).balance);
        selfdestruct(owner);
    }
    
    function changeTokenAddress(address newTokenAddress) onlyOwner public {
        tokenAddress = newTokenAddress;
    }
    
    event SellTransaction(uint256 etherAmount, uint256 tokenAmount);
    event BuyTransaction(uint256 etherAmount, uint256 tokenAmount);
}
```