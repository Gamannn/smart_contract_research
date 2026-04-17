```solidity
pragma solidity ^0.4.23;

contract Lottery {
    address public owner;
    uint private minBet;
    bytes32 private cumulativeHash;
    address[] private participants;
    mapping(address => uint256) winnings;
    uint256 private ownerSharePercentage;
    uint256 private winnerSharePercentage;
    bool private isRunning = true;
    uint256 public gameRunCounter;
    uint256 private minEntriesRequiredPerGame = 1;
    uint256 private potSize;
    uint256 private latestBlockNumber;
    uint256 private minEntryInWei = 0.1 ether;

    event BetStarted(address indexed player, uint amount);
    event BetAccepted(address indexed player, uint amount, uint blockNumber);
    event BetNotPlaced(address indexed player, uint amount, uint blockNumber);
    event StartWinnerDraw(uint256 randomInt, address winner, uint blockNumber, uint256 potSize);
    event AmountWonByOwner(address owner, uint256 amount);
    event AmountWonByWinner(address winner, uint256 amount);
    event StartWithdraw(address indexed player, uint256 amount);
    event SuccessWithdraw(address indexed player, uint256 amount);
    event RollbackWithdraw(address indexed player, uint256 amount);
    event ShowParticipants(address[] participants);
    event ShowBetNumber(uint256 index, address participant);
    event CalledConstructor(uint blockNumber, address owner);
    event SuccessDrawWinner(bool success);
    event NotReadyDrawWinner(bool ready);

    constructor() public {
        owner = msg.sender;
        latestBlockNumber = block.number;
        cumulativeHash = bytes32(0);
        emit CalledConstructor(latestBlockNumber, owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function () public payable {
        if (isRunning) {
            uint betAmount = msg.value;
            emit BetStarted(msg.sender, msg.value);
            require(betAmount >= minEntryInWei);
            assert(betAmount >= minBet);
            cumulativeHash = keccak256(abi.encodePacked(blockhash(latestBlockNumber), cumulativeHash));
            emit BetAccepted(msg.sender, msg.value, block.number);
            latestBlockNumber = block.number;
            participants.push(msg.sender);
            potSize += msg.value;
        } else {
            emit BetNotPlaced(msg.sender, msg.value, block.number);
        }
    }

    function placeBet() public payable returns (bool) {
        if (isRunning) {
            uint betAmount = msg.value;
            emit BetStarted(msg.sender, msg.value);
            require(betAmount >= minEntryInWei);
            assert(betAmount >= minBet);
            cumulativeHash = keccak256(abi.encodePacked(blockhash(latestBlockNumber), cumulativeHash));
            emit BetAccepted(msg.sender, msg.value, block.number);
            latestBlockNumber = block.number;
            participants.push(msg.sender);
            potSize += msg.value;
        } else {
            emit BetNotPlaced(msg.sender, msg.value, block.number);
        }
        return true;
    }

    function drawWinner() private onlyOwner returns (address) {
        assert(participants.length >= minEntriesRequiredPerGame);
        latestBlockNumber = block.number;
        bytes32 randomHash = keccak256(abi.encodePacked(blockhash(latestBlockNumber - 1), cumulativeHash));
        uint256 randomInt = uint256(randomHash) % participants.length;
        address winner = participants[randomInt];
        uint256 winnerAmount = potSize * winnerSharePercentage / 100;
        uint256 ownerAmount = potSize * ownerSharePercentage / 100;

        if (isRunning) {
            winnings[winner] = winnerAmount;
            owner.transfer(ownerAmount);
            emit AmountWonByOwner(owner, ownerAmount);
            if (winnings[winner] > 0) {
                winnings[winner] = 0;
                if (winner.send(winnerAmount)) {
                    emit SuccessWithdraw(winner, winnerAmount);
                    emit AmountWonByWinner(winner, winnerAmount);
                } else {
                    winnings[winner] = winnerAmount;
                    emit RollbackWithdraw(winner, winnerAmount);
                }
            }
        } else {
            winnings[winner] = potSize;
            if (winnings[winner] > 0) {
                winnings[winner] = 0;
                if (winner.send(potSize)) {
                    emit SuccessWithdraw(winner, potSize);
                    emit AmountWonByWinner(winner, potSize);
                } else {
                    winnings[winner] = potSize;
                    emit RollbackWithdraw(winner, potSize);
                }
            }
        }
        cumulativeHash = bytes32(0);
        delete participants;
        potSize = 0;
        emit StartWinnerDraw(randomInt, winner, latestBlockNumber, winnings[winner]);
        return winner;
    }

    function withdraw() private returns (bool) {
        uint256 amount = winnings[msg.sender];
        emit StartWithdraw(msg.sender, amount);
        winnings[msg.sender] = 0;
        if (msg.sender.send(amount)) {
            emit SuccessWithdraw(msg.sender, amount);
            return true;
        } else {
            winnings[msg.sender] = amount;
            emit RollbackWithdraw(msg.sender, amount);
            return false;
        }
    }

    function getParticipants() public onlyOwner returns (address[]) {
        emit ShowParticipants(participants);
        return participants;
    }

    function toggleRunning() public onlyOwner returns (bool) {
        isRunning = !isRunning;
        return isRunning;
    }

    function setMinEntries(uint256 minEntries) public onlyOwner returns (bool) {
        minEntriesRequiredPerGame = minEntries;
        return true;
    }

    function setMinBet(uint256 minBetAmount) public onlyOwner returns (bool) {
        minBet = minBetAmount;
        return true;
    }

    function getParticipant(uint256 index) private onlyOwner returns (address) {
        emit ShowBetNumber(index, participants[index]);
        return participants[index];
    }

    function getMinBet() public view returns (uint256) {
        return minBet;
    }

    function getParticipantCount() public view returns (uint256) {
        return participants.length;
    }

    function getMinEntries() public view returns (uint256) {
        return minEntriesRequiredPerGame;
    }

    function destroyContract() public onlyOwner {
        uint256 balance = potSize;
        owner.transfer(balance);
        selfdestruct(owner);
    }
}
```