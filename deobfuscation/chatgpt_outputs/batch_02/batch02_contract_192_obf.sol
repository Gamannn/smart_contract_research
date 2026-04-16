```solidity
pragma solidity ^0.4.24;

contract OwnerContract {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    modifier onlyEOA() {
        address sender = msg.sender;
        uint256 size;
        assembly {
            size := extcodesize(sender)
        }
        require(size == 0, "sorry humans only");
        _;
    }
}

contract EventsContract {
    event BuyEvent(address indexed buyer, uint amount, uint value);
    event RewardEvent(address indexed receiver, uint amount, uint reward);
}

contract MainContract is OwnerContract, EventsContract {
    using SafeMath for uint;

    address private wallet1;
    address private wallet2;
    uint public startBlock;
    uint public playerCount = 1000;
    bool public isActive = false;
    uint public totalPlayers = 0;

    mapping(address => uint) playerIds;
    mapping(uint => address) playerAddresses;
    mapping(uint => uint) playerLevels;
    mapping(uint => uint) playerRewards;
    mapping(uint => uint) playerBonuses;
    mapping(uint => uint) playerPenalties;
    mapping(address => uint) playerBalances;
    mapping(uint => uint) playerReferrals;
    uint currentRound = 1;
    mapping(uint => address) roundPlayers;
    mapping(uint => uint) roundPlayerIds;

    constructor(address _wallet1, address _wallet2) public {
        wallet1 = _wallet1;
        wallet2 = _wallet2;
        startBlock = block.number + 633;
    }

    function buy(uint amount) public onlyEOA payable returns (uint) {
        require(block.number >= startBlock, "Not Start");
        require(playerAddresses[amount] != 0x0 || (amount == 0 && totalPlayers == 0));
        require(msg.value >= 0.1 ether, "Minima amount: 0.1 ether");

        bool isNewPlayer = false;
        uint playerId;

        if (playerIds[msg.sender] == 0) {
            playerId = playerCount + 1;
            playerIds[msg.sender] = playerId;
            playerLevels[playerId] = amount;
            playerRewards[playerId] = 6;
            playerBonuses[playerId] = 6 * 6;
            playerPenalties[playerId] = 6 * 6 * 6;
            isNewPlayer = true;
        } else {
            playerId = playerIds[msg.sender];
            amount = playerLevels[playerId];
            playerRewards[playerId] += 6;
            playerBonuses[playerId] += 36;
            playerPenalties[playerId] += 216;
        }

        uint referrerId = 0;
        uint referrerBonus = 0;
        uint referrerPenalty = 0;

        if (totalPlayers > 0 && playerBonuses[referrerId] > 0) {
            playerBonuses[referrerId] -= 1;
            if (isNewPlayer) playerReferrals[referrerId] += 1;
        }

        if (playerLevels[referrerId] != 0 && playerPenalties[amount] > 0) {
            uint referrerLevel = playerLevels[referrerId];
            playerPenalties[referrerLevel] -= 1;
            if (isNewPlayer) playerReferrals[referrerLevel] += 1;
        }

        playerAddresses[playerId] = msg.sender;
        roundPlayers[currentRound] = msg.sender;
        roundPlayerIds[currentRound] = playerId;
        playerCount = playerId;

        if (isNewPlayer) totalPlayers += 1;

        emit BuyEvent(msg.sender, playerId, msg.value);
        distributeRewards(referrerId, referrerBonus, referrerPenalty);
    }

    function distributeRewards(uint referrerId, uint referrerBonus, uint referrerPenalty) internal {
        uint reward1 = msg.value.mul(40 ether).div(100 ether);
        uint reward2 = msg.value.mul(30 ether).div(100 ether);
        uint reward3 = msg.value.mul(20 ether).div(100 ether);
        uint reward4 = msg.value.mul(3 ether).div(100 ether);

        if (referrerId != 0) {
            playerAddresses[referrerId].transfer(reward1);
            playerBalances[playerAddresses[referrerId]] = playerBalances[playerAddresses[referrerId]].add(reward1);
            emit RewardEvent(playerAddresses[referrerId], referrerId, reward1);
        }

        if (referrerBonus != 0) {
            playerAddresses[referrerBonus].transfer(reward2);
            playerBalances[playerAddresses[referrerBonus]] = playerBalances[playerAddresses[referrerBonus]].add(reward2);
            emit RewardEvent(playerAddresses[referrerBonus], referrerBonus, reward2);
        }

        if (referrerPenalty != 0) {
            playerAddresses[referrerPenalty].transfer(reward3);
            playerBalances[playerAddresses[referrerPenalty]] = playerBalances[playerAddresses[referrerPenalty]].add(reward3);
            emit RewardEvent(playerAddresses[referrerPenalty], referrerPenalty, reward3);
        }

        wallet1.transfer(reward4);
        wallet2.transfer(reward4);
    }

    function withdraw(uint amount) public onlyOwner {
        owner.transfer(amount);
    }

    function getPlayerInfo() public view returns (uint, uint, uint, uint) {
        uint playerId = playerIds[msg.sender];
        return (
            playerBalances[msg.sender],
            playerReferrals[playerId],
            playerId,
            totalPlayers
        );
    }

    function getPlayerStats() public view returns (uint, uint, uint) {
        uint playerId = playerIds[msg.sender];
        return (
            playerRewards[playerId],
            playerBonuses[playerId],
            playerPenalties[playerId]
        );
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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