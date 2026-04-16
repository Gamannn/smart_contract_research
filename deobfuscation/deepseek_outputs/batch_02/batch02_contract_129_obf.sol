```solidity
pragma solidity ^0.4.11;

interface IERC20 {
    function balanceOf(address owner) constant returns (uint balance);
    function transferFrom(address from, address to, uint value);
    function transfer(address to, uint value);
}

interface IUnicornRanch {
    enum VisitType { Spa, Afternoon, Day, Overnight, Week, Extended }
    enum VisitState { InProgress, Completed, Repossessed }
    
    function getVisitDetails(address visitor, uint visitId) constant returns (
        uint unicornId,
        VisitType visitType,
        uint startTime,
        uint endTime,
        VisitState state,
        uint actualStart,
        uint actualEnd
    );
}

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

contract UnicornReward {
    using SafeMath for uint;
    
    address public tokenAddress;
    address public owner;
    address public unicornRanchAddress;
    
    uint public pricePerUnicorn;
    uint public rewardUnicornAmount;
    
    mapping(address => uint) public balances;
    mapping(address => bool) public hasClaimedReward;
    
    event RewardClaimed(address indexed visitor, uint visitId);
    event UnicornsSold(address indexed buyer, uint amount, uint price, uint total);
    event DonationReceived(address indexed donor, uint amount, uint unicornsReceived);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function UnicornReward() {
        owner = msg.sender;
        pricePerUnicorn = 1 finney;
        rewardUnicornAmount = 100;
    }
    
    function getBalance(address visitor) constant returns (uint balance) {
        return balances[visitor];
    }
    
    function claimReward(uint visitId) {
        IUnicornRanch ranch = IUnicornRanch(unicornRanchAddress);
        var (unicornId, visitType, , , state, actualStart, actualEnd) = ranch.getVisitDetails(msg.sender, visitId);
        
        require(state == IUnicornRanch.VisitState.Completed);
        require(visitType != IUnicornRanch.VisitType.Spa);
        require(actualEnd > actualStart);
        require(hasClaimedReward[msg.sender] == false);
        
        hasClaimedReward[msg.sender] = true;
        balances[msg.sender] = balances[msg.sender].add(rewardUnicornAmount);
        
        RewardClaimed(msg.sender, visitId);
    }
    
    function buyUnicorns(uint amount) {
        require(amount > 0);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, owner, amount);
        
        uint total = amount.mul(pricePerUnicorn);
        UnicornsSold(msg.sender, amount, pricePerUnicorn, total);
    }
    
    function() payable {
        uint unicornsReceived = (msg.value).div(pricePerUnicorn);
        balances[msg.sender] = balances[msg.sender].add(unicornsReceived);
        
        DonationReceived(msg.sender, msg.value, unicornsReceived);
    }
    
    function changeOwner(address newOwner) onlyOwner {
        owner = newOwner;
    }
    
    function changeTokenAddress(address newTokenAddress) onlyOwner {
        tokenAddress = newTokenAddress;
    }
    
    function setUnicornRanchAddress(address ranchAddress) onlyOwner {
        unicornRanchAddress = ranchAddress;
    }
    
    function setPricePerUnicorn(uint price) onlyOwner {
        pricePerUnicorn = price;
    }
    
    function setRewardAmount(uint amount) onlyOwner {
        rewardUnicornAmount = amount;
    }
    
    function setBalance(address visitor, uint balance) onlyOwner {
        balances[visitor] = balance;
    }
    
    function withdraw() onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner, token.balanceOf(address(this)));
    }
    
    function rescueTokens(address tokenContract) onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(owner, token.balanceOf(address(this)));
    }
}
```