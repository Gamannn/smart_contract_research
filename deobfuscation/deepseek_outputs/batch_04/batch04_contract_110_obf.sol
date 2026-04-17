```solidity
pragma solidity ^0.5.0;

contract Oxf2936d678fc2b847d98c5127aff85fbf0af7250b {
    event NewStake(
        address indexed staker,
        uint256 randomNumber,
        uint256 amount,
        uint256 previousRecord,
        uint256 minerPayment
    );
    
    event NewMiner(
        address indexed miner,
        uint256 record,
        uint256 minerPayment
    );
    
    event Status(
        uint256 stakeAmount,
        uint256 record,
        uint256 finalBlock
    );
    
    event PaidOut(
        address indexed miner,
        uint256 amount
    );
    
    address payable public serviceAddress = 0x935F545C5aA388B6846FB7A4c51ED1b180A4eFFF;
    
    uint256 public stakeAmount = 1 wei;
    uint256 public finalBlock = 0;
    uint256 public lastBlock = 0;
    uint256 public record = 0;
    address payable public currentMiner;
    
    function getStakeAmount() public view returns(uint256) {
        return stakeAmount;
    }
    
    function getMinerPayment() public view returns(uint256) {
        uint256 contractBalance = getContractBalance();
        return (contractBalance / 2) + (contractBalance / 4);
    }
    
    function getRecord() public view returns(uint256) {
        return record;
    }
    
    function getCurrentMiner() public view returns(address) {
        return currentMiner;
    }
    
    function getFinalBlock() public view returns(uint256) {
        return finalBlock;
    }
    
    function getPreviousBalance() private view returns(uint256) {
        return address(this).balance - msg.value;
    }
    
    function isRoundActive() private view returns(bool) {
        return block.number >= finalBlock;
    }
    
    function isRoundFinished() private view returns(bool) {
        return block.number >= finalBlock + 11000;
    }
    
    function generateRandomNumber(
        uint256 seed1,
        uint256 seed2,
        uint256 seed3
    ) private pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(seed1, seed2, seed3))) - seed3;
    }
    
    function calculateMinerPayment() private view returns(uint256) {
        uint256 contractBalance = address(this).balance;
        return (contractBalance / 2) + (contractBalance / 4);
    }
    
    function getContractBalance() private view returns(uint256) {
        return address(this).balance;
    }
    
    function calculatePayout() private view returns(uint256) {
        uint256 contractBalance = getContractBalance();
        uint256 minerPayment = (contractBalance / 2) + (contractBalance / 4);
        return contractBalance - minerPayment - (contractBalance / 8);
    }
    
    function () external payable {
        if (msg.sender != tx.origin) {
            return;
        }
        
        processRound();
        
        uint256 previousBalance = getPreviousBalance();
        uint256 minerPayment = calculateMinerPayment();
        uint256 randomNumber = generateRandomNumber(record, previousBalance, msg.value);
        uint256 amount = msg.value;
        
        emit NewStake(msg.sender, randomNumber, msg.value, record, minerPayment);
        
        if (amount < stakeAmount) {
            return;
        }
        
        if (randomNumber < record) {
            record = randomNumber;
            currentMiner = msg.sender;
            stakeAmount = amount;
            finalBlock = block.number + (block.number - lastBlock) + 42;
            
            if (finalBlock > block.number + 11000) {
                finalBlock = block.number + 11000;
            }
            
            lastBlock = block.number;
            emit NewMiner(currentMiner, record, minerPayment);
            emit Status(stakeAmount, record, finalBlock);
        }
    }
    
    function processRound() public {
        if (!isRoundActive()) {
            return;
        }
        
        if (isRoundFinished()) {
            serviceAddress.transfer(getContractBalance() / 2);
            stakeAmount = stakeAmount / 2;
            record = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            lastBlock = block.number - 11000;
            finalBlock = block.number + 11000;
            return;
        }
        
        uint256 contractBalance = getContractBalance();
        uint256 payout = calculatePayout();
        uint256 serviceFee = contractBalance / 8;
        
        currentMiner.transfer(payout);
        serviceAddress.transfer(serviceFee);
        
        emit PaidOut(currentMiner, payout);
        
        stakeAmount = contractBalance - payout - serviceFee;
        record = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        lastBlock = block.number - 11000;
        finalBlock = block.number + 11000;
        
        emit Status(stakeAmount, record, finalBlock);
    }
    
    function getAddressConstant(uint256 index) public view returns(address payable) {
        address payable[] memory addressConstants = new address payable[](2);
        addressConstants[0] = address(0);
        addressConstants[1] = serviceAddress;
        return addressConstants[index];
    }
    
    function getIntegerConstant(uint256 index) internal view returns(uint256) {
        uint256[] memory integerConstants = new uint256[](12);
        integerConstants[0] = 42;
        integerConstants[1] = 5789;
        integerConstants[2] = 69;
        integerConstants[3] = 2;
        integerConstants[4] = 64;
        integerConstants[5] = 7000000;
        integerConstants[6] = 1157;
        integerConstants[7] = 70;
        integerConstants[8] = 100000000;
        integerConstants[9] = 8;
        integerConstants[10] = 11000;
        integerConstants[11] = 1;
        return integerConstants[index];
    }
}
```