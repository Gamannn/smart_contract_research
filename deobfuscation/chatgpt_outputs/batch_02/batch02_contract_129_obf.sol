```solidity
pragma solidity ^0.4.11;

contract TokenInterface {
    function balanceOf(address owner) constant returns (uint);
    function transferFrom(address from, address to, uint value);
    function transfer(address to, uint value);
}

contract VisitContract {
    enum VisitType { Spa, Afternoon, Day, Overnight, Week, Extended }
    enum VisitState { InProgress, Completed, Repossessed }
    
    function getVisitDetails(address visitor, uint visitId) constant returns (
        uint pricePerUnicorn, 
        VisitType visitType, 
        uint startTime, 
        uint endTime, 
        VisitState visitState, 
        uint unicornsSold, 
        uint unicornsRewarded
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

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

contract UnicornRanch {
    using SafeMath for uint;

    address public owner;
    address public unicornTokenAddress;
    address public visitContractAddress;
    uint public pricePerUnicorn;
    uint public rewardUnicornAmount;
    mapping(address => uint) public unicornBalances;
    mapping(address => bool) public rewardClaimed;

    event RewardClaimed(address indexed user, uint visitId);
    event UnicornsSold(address indexed user, uint unicornsSold, uint pricePerUnicorn, uint totalPrice);
    event DonationReceived(address indexed user, uint amount, uint unicornsReceived);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function UnicornRanch(address _unicornTokenAddress, address _visitContractAddress, uint _pricePerUnicorn, uint _rewardUnicornAmount) {
        owner = msg.sender;
        unicornTokenAddress = _unicornTokenAddress;
        visitContractAddress = _visitContractAddress;
        pricePerUnicorn = _pricePerUnicorn;
        rewardUnicornAmount = _rewardUnicornAmount;
    }

    function getUnicornBalance(address user) constant returns (uint) {
        return unicornBalances[user];
    }

    function claimReward(uint visitId) {
        VisitContract visitContract = VisitContract(visitContractAddress);
        var (pricePerUnicorn, visitType, , , visitState, , unicornsRewarded) = visitContract.getVisitDetails(msg.sender, visitId);

        require(visitState == VisitContract.VisitState.Completed);
        require(visitType != VisitContract.VisitType.Spa);
        require(unicornsRewarded > pricePerUnicorn);
        require(!rewardClaimed[msg.sender]);

        rewardClaimed[msg.sender] = true;
        unicornBalances[msg.sender] = unicornBalances[msg.sender].add(rewardUnicornAmount);

        RewardClaimed(msg.sender, visitId);
    }

    function sellUnicorns(uint unicornsToSell) {
        require(unicornsToSell > 0);

        unicornBalances[msg.sender] = unicornBalances[msg.sender].sub(unicornsToSell);

        TokenInterface unicornToken = TokenInterface(unicornTokenAddress);
        unicornToken.transferFrom(msg.sender, owner, unicornsToSell);

        UnicornsSold(msg.sender, unicornsToSell, pricePerUnicorn, unicornsToSell.mul(pricePerUnicorn));
    }

    function() payable {
        uint unicornsReceived = msg.value.div(pricePerUnicorn);
        unicornBalances[msg.sender] = unicornBalances[msg.sender].add(unicornsReceived);

        DonationReceived(msg.sender, msg.value, unicornsReceived);
    }

    function setOwner(address newOwner) onlyOwner {
        owner = newOwner;
    }

    function setUnicornTokenAddress(address newUnicornTokenAddress) onlyOwner {
        unicornTokenAddress = newUnicornTokenAddress;
    }

    function setVisitContractAddress(address newVisitContractAddress) onlyOwner {
        visitContractAddress = newVisitContractAddress;
    }

    function setPricePerUnicorn(uint newPricePerUnicorn) onlyOwner {
        pricePerUnicorn = newPricePerUnicorn;
    }

    function setRewardUnicornAmount(uint newRewardUnicornAmount) onlyOwner {
        rewardUnicornAmount = newRewardUnicornAmount;
    }

    function setUnicornBalance(address user, uint balance) onlyOwner {
        unicornBalances[user] = balance;
    }

    function withdrawUnicorns() onlyOwner {
        TokenInterface unicornToken = TokenInterface(unicornTokenAddress);
        unicornToken.transfer(owner, unicornToken.balanceOf(this));
    }

    function withdrawEther() onlyOwner {
        owner.transfer(this.balance);
    }
}
```