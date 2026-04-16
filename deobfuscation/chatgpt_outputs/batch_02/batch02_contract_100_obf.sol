```solidity
pragma solidity ^0.4.24;

contract MarketContract {
    using SafeMath for uint;

    event MarketBoost(uint amount);
    event NorsefireSwitch(address indexed from, address indexed to, uint amount);

    uint256 public clonesToCreate;
    uint256 public start;
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public userRewards;
    mapping(address => uint256) public lastUpdate;
    mapping(address => address) public userReferrals;

    struct ContractState {
        address owner;
        bool initialized;
        uint256 norsefirePrice;
        uint256 marketCap;
        address treasury;
        uint256 psn;
        uint256 psnh;
        uint256 psnDivisor;
        uint256 psnhDivisor;
    }

    ContractState public state;

    constructor() public {
        state = ContractState({
            owner: msg.sender,
            initialized: false,
            norsefirePrice: 0.1 ether,
            marketCap: 0,
            treasury: 0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae,
            psn: 100,
            psnh: 5000,
            psnDivisor: 10,
            psnhDivisor: 232
        });
    }

    function initializeMarket() public payable {
        require(!state.initialized);
        require(msg.value == 0.00232 ether);
        state.initialized = true;
        state.marketCap = msg.value;
    }

    function buyNorsefire() public payable {
        require(state.initialized);
        require(msg.value >= state.norsefirePrice);

        uint256 norsefireBought = msg.value.div(state.norsefirePrice);
        uint256 norsefireReward = norsefireBought.mul(20).div(100);
        uint256 norsefireFee = norsefireBought.mul(10).div(100);

        userBalances[msg.sender] = userBalances[msg.sender].add(norsefireBought);
        userRewards[msg.sender] = userRewards[msg.sender].add(norsefireReward);
        state.treasury.transfer(norsefireFee);

        emit NorsefireSwitch(state.treasury, msg.sender, msg.value);
    }

    function boostMarket(uint256 amount) public payable {
        require(state.initialized);
        emit MarketBoost(amount);
    }

    function deployIdea(address ref) public {
        require(state.initialized);
        address sender = msg.sender;

        if (userReferrals[sender] == address(0) && userReferrals[sender] != sender) {
            userReferrals[sender] = ref;
        }

        uint256 ideasCreated = clonesToCreate.mul(20).div(100);
        userBalances[sender] = userBalances[sender].add(ideasCreated);
        userRewards[sender] = 0;
        lastUpdate[sender] = now;

        if (userBalances[userReferrals[sender]] > 0) {
            userRewards[userReferrals[sender]] = userRewards[userReferrals[sender]].add(ideasCreated.mul(20).div(100));
        }
    }

    function withdrawRewards() public {
        require(state.initialized);
        address sender = msg.sender;

        uint256 reward = calculateReward(sender);
        userBalances[sender] = userBalances[sender].sub(reward);
        userRewards[sender] = 0;
        lastUpdate[sender] = now;

        sender.transfer(reward);
    }

    function calculateReward(address user) public view returns (uint256) {
        uint256 timePassed = now.sub(lastUpdate[user]);
        uint256 reward = userBalances[user].mul(timePassed).div(2 days);
        return reward;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserBalance() public view returns (uint256) {
        return userBalances[msg.sender];
    }

    function getNorsefirePrice() public view returns (uint256) {
        return state.norsefirePrice;
    }

    function getUserRewards(address user) public view returns (uint256) {
        return userRewards[user];
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