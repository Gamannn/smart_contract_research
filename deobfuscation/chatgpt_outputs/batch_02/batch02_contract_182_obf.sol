```solidity
pragma solidity ^0.4.24;

contract MarketContract {
    using SafeMath for uint;

    event MarketBoost(uint amount);
    event NorsefireSwitch(address oldNorsefire, address newNorsefire, uint newPrice);
    event ClonesDeployed(address deployer, uint amount);
    event IdeasSold(address seller, uint amount);
    event IdeasBought(address buyer, uint amount);

    uint256 public marketBoostFactor = 2;
    uint256 public norsefirePrice;
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public userIdeas;
    mapping(address => uint256) public lastActivity;
    mapping(address => address) public referrals;

    struct ContractState {
        address norsefireAddress;
        bool initialized;
        uint256 norsefirePrice;
        uint256 marketIdeas;
        address marketAddress;
        uint256 marketBoost;
        uint256 marketFactor;
        uint256 marketBoostFactor;
    }

    ContractState public state;

    constructor() public {
        state.norsefireAddress = 0x1337eaD98EaDcE2E04B1cfBf57E111479854D29A;
        state.norsefirePrice = 100000000000000000;
        state.marketIdeas = 0;
        state.marketAddress = 0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae;
        state.marketBoost = 10000;
        state.marketFactor = 3;
        state.marketBoostFactor = 2;
    }

    function initializeNorsefire() public {
        require(!state.initialized);
        state.initialized = true;
        state.norsefireAddress = 0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae;
        state.norsefirePrice = 100000000000000000;
    }

    function switchNorsefire() public payable {
        require(state.initialized);
        require(msg.value >= state.norsefirePrice);

        uint oldPrice = state.norsefirePrice;
        state.norsefirePrice = msg.value.mul(10).div(9);
        uint marketBoost = msg.value.mul(9).div(10);
        address newNorsefire = msg.sender;

        uint norsefireReward = oldPrice.mul(4).div(9);
        state.norsefireAddress.transfer(norsefireReward);
        state.marketAddress.transfer(marketBoost);

        emit NorsefireSwitch(state.norsefireAddress, newNorsefire, state.norsefirePrice);
        state.norsefireAddress = newNorsefire;
    }

    function boostMarket() public payable {
        require(state.initialized);
        emit MarketBoost(msg.value);
    }

    function deployClones(address referrer) public {
        require(state.initialized);

        address sender = msg.sender;
        if (referrals[sender] == address(0) && referrer != sender) {
            referrals[sender] = referrer;
        }

        uint256 userBalance = getUserBalance();
        userBalances[sender] = userBalances[sender].add(userBalance);
        userIdeas[sender] = 0;
        lastActivity[sender] = now;

        if (userBalances[referrals[sender]] > 0) {
            userIdeas[referrals[sender]] = userIdeas[referrals[sender]].add(userBalance.mul(20).div(100));
        }

        state.marketIdeas = state.marketIdeas.add(userBalance.mul(10).div(100));
        emit ClonesDeployed(sender, userBalance);
    }

    function sellIdeas() public {
        require(state.initialized);

        address sender = msg.sender;
        uint256 userBalance = getUserBalance();
        uint256 ideaValue = calculateIdeaSell(userBalance);
        uint256 marketValue = calculateMarketValue(ideaValue);

        userBalances[sender] = userBalances[sender].mul(4).div(10);
        userIdeas[sender] = 0;
        lastActivity[sender] = now;

        state.marketIdeas = state.marketIdeas.add(marketValue.mul(10).div(100));
        state.norsefireAddress.transfer(ideaValue.mul(9).div(10));

        emit IdeasSold(sender, userBalance);
    }

    function buyIdeas() public payable {
        require(state.initialized);

        address sender = msg.sender;
        uint256 amount = msg.value;
        uint256 ideaValue = calculateIdeaBuy(amount);

        state.norsefireAddress.transfer(amount.mul(9).div(10));
        userIdeas[sender] = userIdeas[sender].add(ideaValue);

        emit IdeasBought(sender, ideaValue);
    }

    function calculateIdeaSell(uint256 ideaAmount) public view returns (uint256) {
        return ideaAmount.mul(state.marketBoost).div(state.marketIdeas);
    }

    function calculateIdeaBuy(uint256 amount) public view returns (uint256) {
        return amount.mul(state.marketIdeas).div(state.marketBoost);
    }

    function calculateMarketValue(uint256 ideaAmount) public view returns (uint256) {
        return ideaAmount.mul(4).div(10);
    }

    function getUserBalance() public view returns (uint256) {
        address sender = msg.sender;
        return userIdeas[sender].mul(4).div(10);
    }

    function getMarketIdeas() public view returns (uint256) {
        return state.marketIdeas;
    }

    function getNorsefirePrice() public view returns (uint256) {
        return state.norsefirePrice;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserIdeas(address user) public view returns (uint256) {
        return userIdeas[user];
    }

    function getUserLastActivity(address user) public view returns (uint256) {
        return lastActivity[user];
    }

    function getUserReferral(address user) public view returns (address) {
        return referrals[user];
    }
}

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
```