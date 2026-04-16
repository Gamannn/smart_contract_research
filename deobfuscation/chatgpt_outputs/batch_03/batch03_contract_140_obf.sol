```solidity
pragma solidity ^0.4.18;

contract CoinPlacement {
    struct ContractState {
        uint256 accumulatedReward;
        uint256 maxReward;
        uint256 maxRows;
        uint256 rewardInterval;
        uint256 rewardPercentage;
        uint16 maxColumns;
        uint256 coinPrice;
        address owner;
    }

    ContractState state = ContractState(
        0,
        2 * 0.005 ether,
        5,
        30,
        0,
        10,
        0.005 ether,
        address(0)
    );

    mapping(uint32 => address) public coinOwners;
    uint32[] public placedCoins;
    mapping(address => uint256) public balances;

    event CoinPlaced(uint32 indexed position, address indexed placer);

    function CoinPlacement() public {
        state.owner = msg.sender;
        state.rewardPercentage = 1;
        state.accumulatedReward = 0;
        coinOwners[uint32(0)] = state.owner;
        placedCoins.push(uint32(0));
        CoinPlaced(uint32(0), state.owner);
    }

    function isCoinPlaced(uint16 row, uint16 column) public view returns (bool) {
        return coinOwners[(uint32(row) << 16) | uint16(column)] != 0;
    }

    function getPlacedCoinsCount() external view returns (uint) {
        return placedCoins.length;
    }

    function getPlacedCoins() external view returns (uint32[]) {
        return placedCoins;
    }

    function placeCoin(uint16 row, uint16 column) external payable {
        require(!isCoinPlaced(row, column));
        require(column == 0 || isCoinPlaced(row, column - 1));
        require(row < state.maxColumns || placedCoins.length >= state.maxRows * row);

        uint256 requiredValue = state.coinPrice * (uint256(1) << column);
        require(balances[msg.sender] + msg.value >= requiredValue);

        balances[msg.sender] += (msg.value - requiredValue);

        uint32 position = (uint32(row) << 16) | uint16(column);
        placedCoins.push(position);
        coinOwners[position] = msg.sender;

        if (column == 0) {
            if (state.accumulatedReward < state.maxReward) {
                state.accumulatedReward += state.coinPrice;
            } else {
                balances[state.owner] += state.coinPrice;
            }
        } else {
            uint256 reward = requiredValue * state.rewardPercentage / 100;
            balances[coinOwners[(uint32(row) << 16) | column - 1]] += (requiredValue - reward);
            balances[state.owner] += reward;
        }

        if (placedCoins.length % state.rewardInterval == 0) {
            balances[msg.sender] += state.accumulatedReward;
            state.accumulatedReward = 0;
        }

        CoinPlaced(position, msg.sender);
    }

    function withdraw(uint256 amount) external {
        require(amount != 0);
        require(balances[msg.sender] >= amount);

        balances[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }

    function changeOwner(address newOwner) external {
        require(msg.sender == state.owner);
        state.owner = newOwner;
    }

    function setRewardPercentage(uint256 percentage) external {
        require(msg.sender == state.owner);
        if (percentage <= 2) state.rewardPercentage = percentage;
    }

    function() external payable {
        balances[state.owner] += msg.value;
    }
}
```