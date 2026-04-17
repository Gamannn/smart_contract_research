```solidity
pragma solidity ^0.5.0;

contract StakingContract {
    event NewStake(address indexed staker, uint256 stakeAmount, uint256 currentBalance, uint256 highestStake, uint currentBlock);
    event NewMiner(address indexed miner, uint256 highestStake, uint currentBlock);
    event Status(uint currentBlock, uint256 highestStake, uint totalStakes);
    event PaidOut(address indexed miner, uint payoutAmount);

    address payable owner;
    uint public minimumStake = 1 wei;
    uint public totalStakes = 0;
    uint public highestStake = 0;
    address payable public highestStaker;
    uint public lastBlock;
    uint public blockInterval = 11000;

    constructor() public {
        owner = msg.sender;
    }

    function getMinimumStake() public view returns(uint) {
        return minimumStake;
    }

    function getHalfBalance() public view returns(uint) {
        uint balance = address(this).balance;
        return (balance / 2) + (balance / 4);
    }

    function getHighestStake() public view returns(uint) {
        return highestStake;
    }

    function getHighestStaker() public view returns(address) {
        return highestStaker;
    }

    function getTotalStakes() public view returns(uint) {
        return totalStakes;
    }

    function getCurrentBalance() private view returns(uint) {
        return address(this).balance - msg.value;
    }

    function isBlockIntervalPassed() private view returns(bool) {
        return block.number >= lastBlock + blockInterval;
    }

    function calculateHash(uint a, uint b, uint c) private pure returns(uint) {
        return uint256(keccak256(abi.encodePacked(a, b, c))) - c;
    }

    function getQuarterBalance() private view returns(uint) {
        uint balance = address(this).balance;
        return (balance / 2) + (balance / 4);
    }

    function () external payable {
        if (msg.sender != tx.origin) {
            return;
        }
        processStake();
        uint currentBalance = getCurrentBalance();
        uint quarterBalance = getQuarterBalance();
        uint stakeHash = calculateHash(highestStake, currentBalance, msg.value);
        uint stakeAmount = msg.value;

        emit NewStake(msg.sender, stakeHash, msg.value, highestStake, quarterBalance);

        if (stakeAmount < minimumStake) {
            return;
        }

        if (stakeHash < highestStake) {
            highestStake = stakeHash;
            highestStaker = msg.sender;
            lastBlock = block.number + (blockInterval - 7) + 42;

            if (totalStakes > lastBlock + blockInterval) {
                totalStakes = block.number + blockInterval;
            }

            totalStakes = block.number;
            emit NewMiner(highestStaker, highestStake, quarterBalance);
            emit Status(minimumStake, highestStake, totalStakes);
        }
    }

    function processStake() public {
        if (!isBlockIntervalPassed()) {
            return;
        }

        if (isBlockIntervalPassed()) {
            owner.transfer(getHalfBalance() / 2);
            minimumStake = minimumStake / 2;
            highestStake = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            totalStakes = block.number - blockInterval;
            lastBlock = block.number + blockInterval;
            return;
        }

        uint currentBalance = getCurrentBalance();
        uint payoutAmount = getQuarterBalance() / 8;
        highestStaker.transfer(payoutAmount);
        owner.transfer(payoutAmount);

        emit PaidOut(highestStaker, payoutAmount);

        minimumStake = 1;
        highestStake = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        totalStakes = block.number - blockInterval;
        lastBlock = block.number + blockInterval;

        emit Status(minimumStake, highestStake, totalStakes);
    }
}
```