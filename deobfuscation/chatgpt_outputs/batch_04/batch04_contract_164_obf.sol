```solidity
pragma solidity ^0.6.0;

interface ExternalContract {
    function execute() payable external;
}

contract Lottery {
    ExternalContract public externalContract;
    RNG public rng;
    uint public totalSentToStakeHolders;
    uint public totalMined;
    uint public totalEthFee;
    uint public totalMneFee;
    uint public totalStakeHoldersFee;
    uint public totalSystemNumber;
    uint public totalMaxNumberHolders;
    uint public totalPreviousEndPeriod;
    address public owner;
    uint public maxNumberHolders;
    uint public systemNumber;
    uint public previousEndPeriod;
    address[] public winners;
    uint[] public winnerAmounts;
    uint[] public winnerTimestamps;
    address[] public losers;
    uint[] public loserAmounts;
    uint[] public loserTimestamps;

    event Numbers(address indexed player, uint[] numbers, string message);

    constructor() public {
        externalContract = ExternalContract(0x7eE48259C4A894065d4a5282f230D00908Fd6D96);
        owner = msg.sender;
        rng = new RNG(1588447830, 1588447830 + 2629743, address(this));
    }

    function play(address player, uint256[] memory numbers) public payable returns (uint256) {
        require(msg.sender == address(externalContract));
        if (block.timestamp > previousEndPeriod) {
            rng = new RNG(previousEndPeriod, previousEndPeriod + 2629743, address(this));
            previousEndPeriod = block.timestamp;
        }

        uint[] memory generatedNumbers = new uint[](numbers[0]);
        (generatedNumbers, bool win) = rng.generateNumbers(numbers[0], systemNumber, maxNumberHolders, player);

        uint valueStakeHolderFee = totalSystemNumber + maxNumberHolders * totalStakeHoldersFee / 100;
        if (win) {
            address payable winner = payable(player);
            uint balance = address(this).balance;
            emit Numbers(msg.sender, generatedNumbers, "You WON!");
            uint prize = balance * totalStakeHoldersFee / 100;
            uint netPrize = prize - totalEthFee;
            if (!winner.send(netPrize)) revert('Error While Sending Prize.');
            totalSentToStakeHolders += netPrize;
            winners.push(player);
            winnerAmounts.push(netPrize);
            winnerTimestamps.push(block.timestamp);
        } else {
            losers.push(player);
            loserAmounts.push(numbers[0]);
            loserTimestamps.push(block.timestamp);
            emit Numbers(msg.sender, generatedNumbers, "Your numbers don't match the System Number! Try Again.");
        }

        totalMined += numbers[0];
        uint totalMneFee = totalMined * numbers[0];
        if (msg.value < totalEthFee) revert('Not enough ETH.');
        externalContract.execute{value: totalMneFee}();
        totalEthFee += totalMneFee;
        return totalSentToStakeHolders;
    }

    function withdraw() public {
        if (msg.sender == owner) {
            address payable ownerPayable = payable(msg.sender);
            uint balance = address(this).balance;
            if (!ownerPayable.send(balance)) revert('Error While Executing Withdraw.');
        } else {
            revert();
        }
    }

    function updateFees(uint ethFee, uint mneFee, uint stakeHoldersFee) public {
        if (msg.sender == owner) {
            totalEthFee = ethFee;
            totalMneFee = mneFee;
            totalStakeHoldersFee = stakeHoldersFee;
        } else {
            revert();
        }
    }

    function updateSystemNumber(uint newSystemNumber) public {
        if (msg.sender == owner) {
            systemNumber = newSystemNumber;
        } else {
            revert();
        }
    }

    function updateMaxNumberHolders(uint newMaxNumberHolders) public {
        if (msg.sender == owner) {
            maxNumberHolders = newMaxNumberHolders;
        } else {
            revert();
        }
    }

    function updateExternalContract(address newExternalContract) public {
        if (msg.sender == owner) {
            externalContract = ExternalContract(newExternalContract);
        } else {
            revert();
        }
    }
}

contract RNG {
    address public owner;
    uint public periodStart;
    uint public periodEnd;

    constructor(uint start, uint end, address _owner) public {
        owner = _owner;
        periodStart = start;
        periodEnd = end;
    }

    function generateNumbers(uint count, uint systemNumber, uint maxNumber, address player) public view returns (uint[] memory, bool) {
        require(msg.sender == owner);
        if (!(block.timestamp >= periodStart && block.timestamp <= periodEnd)) revert('wrong timestamp');

        uint[] memory numbers = new uint[](count);
        uint index = 0;
        bool win = false;

        while (index < count) {
            numbers[index] = uint256(keccak256(abi.encodePacked(block.timestamp, player, index))) % maxNumber;
            if (numbers[index] == systemNumber) win = true;
            index++;
        }

        return (numbers, win);
    }
}
```