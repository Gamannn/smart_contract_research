pragma solidity ^0.4.11;

library MathLibrary {
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

contract ERC20Token {
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
    event EtherReceived(address indexed from, uint256 value);
    event EtherWithdrawn(uint256 value);
    event TokensWithdrawn(uint256 value);
    event ICOPurchased(uint256 value);
    event ICOStartBlockChanged(uint256 newStartBlock);
    event ICOStartTimeChanged(uint256 newStartTime);
    event ExecutorChanged(address newExecutor);
    event CrowdSaleChanged(address newCrowdSale);
    event TokenChanged(address newToken);
    event PurchaseCapChanged(uint256 newPurchaseCap);
    event MinimumContributionChanged(uint256 newMinimumContribution);

    uint256 public icoStartBlock;
    address public crowdSaleAddress;
    uint256 public icoStartTime;
    uint256 public purchaseCap;
    uint256 public minimumContribution;
    address public executor;

    function ICOContract(
        address _executor,
        address _crowdSaleAddress,
        uint256 _icoStartBlock,
        uint256 _icoStartTime,
        uint256 _purchaseCap
    ) {
        executor = _executor;
        crowdSaleAddress = _crowdSaleAddress;
        icoStartBlock = _icoStartBlock;
        icoStartTime = _icoStartTime;
        purchaseCap = _purchaseCap;
    }

    function changeCrowdSale(address _crowdSaleAddress) onlyOwner {
        crowdSaleAddress = _crowdSaleAddress;
        CrowdSaleChanged(crowdSaleAddress);
    }

    function changeICOStartBlock(uint256 _icoStartBlock) onlyOwner {
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

    function withdrawTokens(address tokenAddress) onlyOwner {
        ERC20Token token = ERC20Token(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance != 0);
        assert(token.transfer(owner, balance));
        TokensWithdrawn(balance);
    }

    function () payable {
        if ((icoStartBlock != 0) && (block.number < icoStartBlock)) return;
        if ((icoStartTime != 0) && (now < icoStartTime)) return;
        if (this.balance < minimumContribution) return;

        uint256 purchaseAmount = MathLibrary.min(this.balance, purchaseCap);
        assert(crowdSaleAddress.call.value(purchaseAmount)());
        ICOPurchased(purchaseAmount);

        EtherReceived(msg.sender, msg.value);
    }

    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

    function getCurrentTime() internal constant returns (uint256) {
        return now;
    }
}