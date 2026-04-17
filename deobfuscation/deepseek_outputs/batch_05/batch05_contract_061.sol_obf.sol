```solidity
pragma solidity ^0.4.11;

library SafeMath {
    function max(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }
    
    function min(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }
    
    function max(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }
    
    function min(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

contract ERC20 {
    uint256 public totalSupply;
    
    function balanceOf(address owner) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract ICOContract is Ownable {
    event EtherReceived(address indexed sender, uint256 amount);
    event EtherWithdrawn(uint256 amount);
    event TokensWithdrawn(uint256 amount);
    event ICOPurchased(uint256 amount);
    event ICOStartBlockChanged(uint256 newStartBlock);
    event ICOStartTimeChanged(uint256 newStartTime);
    event ExecutorChanged(address newExecutor);
    event CrowdSaleChanged(address newCrowdSale);
    event TokenChanged(address newToken);
    event PurchaseCapChanged(uint256 newPurchaseCap);
    event MinimumContributionChanged(uint256 newMinimumContribution);
    
    uint256 public icoStartBlock;
    address public executor;
    address public crowdSale;
    address public token;
    uint256 public purchaseCap;
    uint256 public minimumContribution;
    uint256 public icoStartTime;
    
    function ICOContract(
        address _executor,
        address _crowdSale,
        uint256 _icoStartBlock,
        uint256 _icoStartTime,
        uint256 _purchaseCap
    ) {
        executor = _executor;
        crowdSale = _crowdSale;
        icoStartBlock = _icoStartBlock;
        icoStartTime = _icoStartTime;
        purchaseCap = _purchaseCap;
        minimumContribution = 0.1 ether;
        owner = msg.sender;
    }
    
    modifier onlyExecutorOrOwner() {
        require(msg.sender == executor || msg.sender == owner);
        _;
    }
    
    function changeCrowdSale(address _crowdSale) onlyExecutorOrOwner {
        crowdSale = _crowdSale;
        CrowdSaleChanged(crowdSale);
    }
    
    function changeICOStartBlock(uint256 _icoStartBlock) onlyExecutorOrOwner {
        icoStartBlock = _icoStartBlock;
        ICOStartBlockChanged(icoStartBlock);
    }
    
    function changeMinimumContribution(uint256 _minimumContribution) onlyOwner {
        minimumContribution = _minimumContribution;
        MinimumContributionChanged(minimumContribution);
    }
    
    function changeICOStartTime(uint256 _icoStartTime) onlyOwner {
        icoStartTime = _icoStartTime;
        ICOStartTimeChanged(icoStartTime);
    }
    
    function changePurchaseCap(uint256 _purchaseCap) onlyOwner {
        purchaseCap = _purchaseCap;
        PurchaseCapChanged(purchaseCap);
    }
    
    function changeExecutor(address _executor) onlyOwner {
        executor = _executor;
        ExecutorChanged(executor);
    }
    
    function withdrawEther() onlyOwner {
        require(this.balance != 0);
        owner.transfer(this.balance);
        EtherWithdrawn(this.balance);
    }
    
    function withdrawTokens(address _token) onlyOwner {
        ERC20 tokenContract = ERC20(_token);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance != 0);
        assert(tokenContract.transfer(owner, balance));
        TokensWithdrawn(balance);
    }
    
    function() payable {
        if ((icoStartBlock != 0) && (block.number < icoStartBlock)) return;
        if ((icoStartTime != 0) && (now < icoStartTime)) return;
        
        if (this.balance < minimumContribution) return;
        
        uint256 amount = SafeMath.min(this.balance, purchaseCap);
        assert(crowdSale.call.value(amount)());
        ICOPurchased(amount);
        
        EtherReceived(msg.sender, msg.value);
    }
    
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }
    
    function getNow() internal constant returns (uint256) {
        return now;
    }
}
```