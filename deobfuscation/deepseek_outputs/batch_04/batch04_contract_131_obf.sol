```solidity
pragma solidity ^0.4.18;

contract ERC20 {
    function totalSupply() constant public returns (uint);
    function balanceOf(address who) constant public returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function allowance(address owner, address spender) constant public returns (uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TokenSale is Ownable {
    address public tokenAddress;
    uint public tokenRate;
    uint public minPurchase;
    uint public maxPurchase;
    uint public tokensAvailable;
    uint public tokensSold;
    
    event Sent(address indexed buyer, uint256 amountPaid, uint256 tokensBought);
    
    function TokenSale(
        address _tokenAddress,
        uint _tokenRate,
        uint _minPurchase,
        uint _maxPurchase,
        uint _tokensAvailable,
        uint _tokensSold
    ) public {
        tokenAddress = _tokenAddress;
        tokenRate = _tokenRate;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        tokensAvailable = _tokensAvailable;
        tokensSold = _tokensSold;
    }
    
    function withdrawTokens(address token, uint amount) onlyOwner public {
        require(ERC20(token).transfer(owner, amount));
    }
    
    function withdrawEther(uint amount) onlyOwner public {
        require(this.balance >= amount);
        owner.transfer(amount);
    }
    
    function setTokenRate(uint newRate) onlyOwner public {
        tokenRate = newRate;
    }
    
    function setMinPurchase(uint newMin) onlyOwner public {
        minPurchase = newMin;
    }
    
    function setTokenAddress(address newToken) onlyOwner public {
        require(newToken != address(0));
        tokenAddress = newToken;
    }
    
    function setMaxPurchase(uint newMax) onlyOwner public {
        require(newMax > 0);
        maxPurchase = newMax;
    }
    
    function buyTokens(uint tokenAmount) public {
        require(tokenRate > 0);
        
        uint etherBalance = this.balance;
        uint maxTokensByEther = etherBalance / tokenRate;
        
        if (tokenAmount > maxTokensByEther) {
            tokenAmount = maxTokensByEther;
        }
        
        require(tokenAmount >= minPurchase);
        require(tokenAmount <= maxPurchase);
        
        require(ERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount));
        
        uint etherAmount = tokenAmount * tokenRate;
        msg.sender.transfer(etherAmount);
        
        uint remainingTokens = tokensAvailable - tokenAmount;
        
        if (remainingTokens >= tokensSold) {
            tokensAvailable = remainingTokens;
            tokensSold = tokensSold + tokenAmount * 1;
        }
        
        Sent(msg.sender, etherAmount, tokenAmount);
    }
    
    function sellTokens() payable public {
        require(tokenRate > 0);
        
        uint tokenAmount = msg.value / tokenRate;
        
        if (tokenAmount < minPurchase) {
            tokenAmount = minPurchase;
        }
        
        uint tokenBalance = ERC20(tokenAddress).balanceOf(address(this));
        require(tokenAmount <= tokenBalance);
        
        uint etherNeeded = tokenAmount * tokenRate;
        uint refund = 0;
        
        if (msg.value > etherNeeded) {
            refund = msg.value - etherNeeded;
        }
        
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
        
        require(ERC20(tokenAddress).transfer(msg.sender, tokenAmount));
        
        tokensSold = tokensSold + tokenAmount * 1;
        tokenRate = tokenRate + tokenAmount * 1;
        
        Sent(msg.sender, msg.value - refund, tokenAmount);
    }
    
    function() payable public {
        sellTokens();
    }
}
```