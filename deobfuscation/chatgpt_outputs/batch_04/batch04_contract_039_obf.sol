```solidity
pragma solidity ^0.5.0;

contract StakingContract {
    event NewStake(address indexed staker, uint256 amount, uint256 totalStaked, uint256 blockNumber, uint timestamp);
    event NewMiner(address indexed miner, uint256 amount, uint timestamp);
    event Status(uint currentStake, uint256 totalStaked, uint lastBlock);
    event PaidOut(address indexed miner, uint amount);

    address payable owner;
    uint public currentStake = 1;
    uint public finalBlock;
    address payable public currentMiner;
    uint256 public totalStaked = 0;
    uint256 public lastBlock = 0;

    function getCurrentStake() public view returns(uint) {
        return currentStake;
    }

    function getHalfAndQuarterBalance() public view returns(uint) {
        uint balance = getContractBalance();
        return (balance / 2) + (balance / 4);
    }

    function getTotalStaked() public view returns(uint) {
        return totalStaked;
    }

    function getCurrentMiner() public view returns(address) {
        return currentMiner;
    }

    function getLastBlock() public view returns(uint) {
        return lastBlock;
    }

    function getFinalBlock() public view returns(uint) {
        return finalBlock;
    }

    function getContractBalance() private view returns(uint) {
        return address(this).balance - msg.value;
    }

    function isFinalBlockReached() private view returns(bool) {
        return block.number >= finalBlock;
    }

    function isFinalBlockExceeded() private view returns(bool) {
        return block.number >= finalBlock + 11000;
    }

    function calculateHash(uint a, uint b, uint c, uint d) private pure returns(uint) {
        return uint256(keccak256(abi.encodePacked(a, b, c, d))) - d;
    }

    function calculateHalfAndQuarterBalance() private view returns(uint) {
        uint balance = address(this).balance;
        return (balance / 2) + (balance / 4);
    }

    function () external payable {
        if (msg.sender != tx.origin) {
            return;
        }
        processStake();
        uint halfAndQuarterBalance = calculateHalfAndQuarterBalance();
        uint stakeAmount = msg.value;
        uint hashValue = calculateHash(totalStaked, finalBlock, uint256(currentMiner), stakeAmount);
        emit NewStake(msg.sender, stakeAmount, totalStaked, block.number, now);

        if (stakeAmount < currentStake) {
            return;
        }

        if (hashValue < totalStaked) {
            totalStaked = hashValue;
            currentMiner = msg.sender;
            finalBlock = block.number + 11000;
            currentStake = halfAndQuarterBalance;
            emit NewMiner(currentMiner, totalStaked, now);
            emit Status(currentStake, totalStaked, lastBlock);
        }
    }

    function processStake() public {
        if (!isFinalBlockReached()) {
            return;
        }

        if (isFinalBlockExceeded()) {
            owner.transfer(getContractBalance() / 2);
            currentStake = currentStake / 2;
            totalStaked = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            lastBlock = block.number - 11000;
            finalBlock = block.number + 11000;
            return;
        }

        uint balance = getContractBalance();
        uint halfAndQuarterBalance = getHalfAndQuarterBalance();
        uint eighthBalance = balance / 8;
        currentMiner.transfer(halfAndQuarterBalance);
        owner.transfer(eighthBalance);
        emit PaidOut(currentMiner, halfAndQuarterBalance);
        currentStake = 64;
        totalStaked = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        lastBlock = block.number - 11000;
        finalBlock = block.number + 11000;
        totalStaked = 0;
        emit Status(currentStake, totalStaked, lastBlock);
    }
}
```