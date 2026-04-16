```solidity
pragma solidity ^0.4.11;

contract Token {
    function transfer(address to, uint amount);
    function balanceOf(address who) constant returns (uint balance);
}

contract ICO {
    mapping (address => uint256) public tokenPurchases;
    mapping (address => uint256) public ethContributions;
    
    uint256 public totalTokensAvailable = 52500;
    uint256 public totalTokensPurchased;
    
    bool public halted;
    address public owner = 0xB00Ae1e677B27Eee9955d632FF07a8590210B366;
    Token public tokenContract = Token(0xB97048628DB6B661D4C2aA833e95Dbe1A905B280);
    
    function haltPurchases() {
        if(msg.sender != owner) throw;
        halted = true;
    }
    
    function releaseTokens() payable {
        if(block.number > 4199999 && tokenPurchases[msg.sender] > tokenContract.balanceOf(address(this))) {
            uint256 userContribution = ethContributions[msg.sender];
            if(userContribution == 0 || tokenPurchases[msg.sender] == 0) throw;
            
            totalTokensPurchased -= tokenPurchases[msg.sender];
            tokenPurchases[msg.sender] = 0;
            msg.sender.transfer(userContribution);
            return;
        }
        
        if(tokenContract.balanceOf(address(this)) == 0 || tokenPurchases[msg.sender] > tokenContract.balanceOf(address(this))) throw;
        
        uint256 userTokens = tokenPurchases[msg.sender];
        uint256 userEth = ethContributions[msg.sender];
        
        if(userTokens == 0 || userEth == 0) throw;
        
        tokenPurchases[msg.sender] = 0;
        ethContributions[msg.sender] = 0;
        tokenContract.transfer(msg.sender, userTokens);
        owner.transfer(userEth);
    }
    
    function purchaseTokens() payable {
        if(halted) throw;
        
        uint256 tokensToBuy = 160 * msg.value;
        
        if((totalTokensPurchased + tokensToBuy) > totalTokensAvailable) throw;
        
        tokenPurchases[msg.sender] += tokensToBuy;
        ethContributions[msg.sender] += msg.value;
        totalTokensPurchased += tokensToBuy;
    }
    
    function () payable {
        if(msg.value == 0) {
            releaseTokens();
        } else {
            purchaseTokens();
        }
    }
}
```