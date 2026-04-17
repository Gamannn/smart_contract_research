```solidity
pragma solidity ^0.4.24;

contract SimpleDepositContract {
    address owner;
    mapping(address => uint256) balances;
    mapping(address => uint256) depositTimestamps;

    uint256[] public constants = [0, 5900, 7, 100, 10];

    constructor() public {
        owner = msg.sender;
    }

    function() external payable {
        if (balances[msg.sender] != 0) {
            address sender = msg.sender;
            sender.send(getRewardAmount());
        }
        depositTimestamps[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
    }

    function getRewardAmount() internal view returns (uint256) {
        return constants[4];
    }
}
```