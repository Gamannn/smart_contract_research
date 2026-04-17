```solidity
pragma solidity ^0.5.0;

contract MiningGame {
    event NewStake(
        address indexed staker,
        uint256 stakeAmount,
        uint256 totalStaked,
        uint256 target,
        uint256 minStake
    );
    
    event NewMiner(
        address indexed miner,
        uint256 target,
        uint256 minStake
    );
    
    event Status(
        uint256 minStake,
        uint256 target,
        uint256 finalBlock
    );
    
    event PaidOut(
        address indexed miner,
        uint256 payout
    );
    
    address payable public serviceAddress;
    uint256 public minStake = 1;
    uint256 public finalBlock;
    uint256 public lastBlock;
    address payable public currentMiner;
    uint256 public target;
    uint256 public totalStaked = 0;
    
    constructor() public {
        serviceAddress = 0x935F545C5aA388B6846FB7A4c51ED1b180A4eFFF;
        currentMiner = address(0);
        target = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        lastBlock = block.number;
        finalBlock = block.number + 11000;
    }
    
    function getMinStake() public view returns(uint256) {
        return minStake;
    }
    
    function getMinerPayout() public view returns(uint256) {
        uint256 contractBalance = getContractBalance();
        return (contractBalance / 2) + (contractBalance / 4);
    }
    
    function getTarget() public view returns(uint256) {
        return target;
    }
    
    function getCurrentMiner() public view returns(address) {
        return currentMiner;
    }
    
    function getFinalBlock() public view returns(uint256) {
        return finalBlock;
    }
    
    function getLastBlock() public view returns(uint256) {
        return lastBlock;
    }
    
    function getContractBalance() private view returns(uint256) {
        return address(this).balance;
    }
    
    function isRoundActive() private view returns(bool) {
        return block.number >= lastBlock;
    }
    
    function isRoundFinished() private view returns(bool) {
        return block.number >= lastBlock + 11000;
    }
    
    function calculateHash(
        uint256 targetValue,
        uint256 totalStakedValue,
        uint256 minerAddress,
        uint256 stakeAmount
    ) private pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(
            targetValue,
            totalStakedValue,
            minerAddress,
            stakeAmount
        ))) - stakeAmount;
    }
    
    function getCurrentPayout() private view returns(uint256) {
        uint256 contractBalance = getContractBalance();
        return (contractBalance / 2) + (contractBalance / 4);
    }
    
    function () external payable {
        if (msg.sender != tx.origin) {
            return;
        }
        
        processRound();
        
        uint256 currentPayout = getCurrentPayout();
        uint256 stakeAmount = msg.value;
        uint256 hashResult = calculateHash(
            target,
            totalStaked,
            uint256(currentMiner),
            stakeAmount
        );
        
        emit NewStake(msg.sender, stakeAmount, totalStaked, target, minStake);
        
        if (stakeAmount < minStake) {
            return;
        }
        
        if (hashResult < target) {
            target = hashResult;
            currentMiner = msg.sender;
            lastBlock = block.number + (block.number - lastBlock) + 42;
            
            if (finalBlock < (block.number + 11000)) {
                finalBlock = block.number + 11000;
            }
            
            lastBlock = block.number;
            finalBlock = block.number + 11000;
        }
        
        totalStaked += stakeAmount;
        emit NewMiner(currentMiner, target, minStake);
        emit Status(minStake, target, finalBlock);
    }
    
    function processRound() public {
        if (!isRoundActive()) {
            return;
        }
        
        if (isRoundFinished()) {
            serviceAddress.transfer(getContractBalance() / 2);
            minStake = minStake / 2;
            target = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            lastBlock = block.number - 11000;
            finalBlock = block.number + 11000;
            return;
        }
        
        uint256 contractBalance = getContractBalance();
        uint256 minerPayout = getMinerPayout();
        uint256 serviceFee = contractBalance / 8;
        
        currentMiner.transfer(minerPayout);
        serviceAddress.transfer(serviceFee);
        
        emit PaidOut(currentMiner, minerPayout);
        
        minStake = minStake * 64;
        target = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        lastBlock = block.number - 11000;
        finalBlock = block.number + 11000;
        totalStaked = 0;
        
        emit Status(minStake, target, finalBlock);
    }
}
```