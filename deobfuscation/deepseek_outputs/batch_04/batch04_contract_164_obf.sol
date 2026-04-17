```solidity
pragma solidity ^0.6.0;

interface IRNG {
    function generateRandom() payable external;
}

contract Lottery {
    IRNG public rngContract;
    RNGGenerator public rngGenerator;
    
    uint public periodStart;
    uint public periodEnd;
    uint public systemNumber;
    uint public maxNumber;
    uint public ticketPrice;
    uint public totalTicketsSold;
    uint public totalSentToStakeHolders;
    uint public totalFeesCollected;
    uint public ethFee;
    uint public mneFee;
    uint public percentWin;
    uint public stakeHoldersFee;
    
    address public owner;
    address public previousWinner;
    bool public win;
    
    address[] public winners;
    uint[] public winningTicketNumbers;
    uint[] public winningAmounts;
    uint[] public winningTimestamps;
    
    address[] public losers;
    uint[] public losingTicketNumbers;
    uint[] public losingTimestamps;
    
    event Numbers(address indexed player, uint[] numbers, string message);
    
    constructor() public {
        rngContract = IRNG(0x7eE48259C4A894065d4a5282f230D00908Fd6D96);
        owner = payable(msg.sender);
        rngGenerator = new RNGGenerator(1588447830, periodEnd, address(this));
    }
    
    function receivePayment() external payable {}
    
    function play(address player, uint256[] memory ticketData) public payable returns (uint256) {
        require(msg.sender == address(rngContract));
        
        if (block.timestamp > periodEnd) {
            rngGenerator = new RNGGenerator(periodStart, (periodStart + 2629743), address(this));
            periodEnd = periodStart + 2629743;
            win = false;
        }
        
        uint[] memory generatedNumbers = new uint[](ticketData[0]);
        (generatedNumbers, win) = rngGenerator.generateNumbers(
            ticketData[0], 
            systemNumber, 
            maxNumber, 
            player
        );
        
        uint valueStakeHolders = stakeHoldersFee / 100;
        
        if (win) {
            address payable playerPayable = payable(player);
            uint contractBalance = address(this).balance;
            emit Numbers(msg.sender, generatedNumbers, "You WON!");
            
            uint winAmount = contractBalance * percentWin / 100;
            uint netWinAmount = winAmount - stakeHoldersFee;
            
            if (!playerPayable.send(netWinAmount)) revert('Error While Executing payment.');
            
            totalSentToStakeHolders += netWinAmount;
            
            winners.push(player);
            winningTicketNumbers.push(ticketData[0]);
            winningAmounts.push(netWinAmount);
            winningTimestamps.push(block.timestamp);
        } else {
            losers.push(player);
            losingTicketNumbers.push(ticketData[0]);
            losingTimestamps.push(block.timestamp);
            emit Numbers(msg.sender, generatedNumbers, "Your numbers don't match the System Number! Try Again.");
        }
        
        totalTicketsSold += ticketData[0];
        uint totalMneFee = mneFee * ticketData[0];
        uint totalEthFee = ethFee * ticketData[0];
        
        if (msg.value < totalEthFee) revert('Not enough ETH.');
        
        rngContract.generateRandom{value: totalMneFee}();
        totalFeesCollected += totalMneFee;
        
        return ticketData[0];
    }
    
    function withdraw() public {
        if (msg.sender == owner) {
            address payable ownerPayable = payable(msg.sender);
            uint contractBalance = address(this).balance;
            if (!ownerPayable.send(contractBalance)) revert('Error While Executing withdrawal.');
        } else {
            revert();
        }
    }
    
    function setFees(uint _stakeHoldersFee, uint _percentWin, uint _ethFee) public {
        if (msg.sender == owner) {
            stakeHoldersFee = _stakeHoldersFee;
            percentWin = _percentWin;
            ethFee = _ethFee;
        } else {
            revert();
        }
    }
    
    function updateSystemNumber(uint _systemNumber) public {
        if (msg.sender == owner) {
            systemNumber = _systemNumber;
        } else {
            revert();
        }
    }
    
    function updateMaxNumber(uint _maxNumber) public {
        if (msg.sender == owner) {
            maxNumber = _maxNumber;
        } else {
            revert();
        }
    }
    
    function updateRNGContract(address _newRNGContract) public {
        if (msg.sender == owner) {
            rngContract = IRNG(_newRNGContract);
        } else {
            revert();
        }
    }
}

contract RNGGenerator {
    address public owner;
    uint public periodStart;
    uint public periodEnd;
    
    constructor(uint _periodStart, uint _periodEnd, address _owner) public {
        owner = _owner;
        periodStart = _periodStart;
        periodEnd = _periodEnd;
    }
    
    function generateNumbers(
        uint count, 
        uint systemNumber, 
        uint maxNumber, 
        address player
    ) public view returns (uint[] memory, bool) {
        require(msg.sender == owner);
        
        if (!(block.timestamp >= periodStart && block.timestamp <= periodEnd))
            revert('wrong timestamp');
            
        uint[] memory numbers = new uint[](count);
        uint i = 0;
        bool win = false;
        
        while (i < count) {
            numbers[i] = uint256(
                uint256(
                    keccak256(
                        abi.encodePacked(block.timestamp, player, i)
                    )
                ) % maxNumber
            );
            
            if (numbers[i] == systemNumber) win = true;
            i++;
        }
        
        return (numbers, win);
    }
}
```