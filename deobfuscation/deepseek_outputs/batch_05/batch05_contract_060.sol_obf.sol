```solidity
pragma solidity ^0.4.23;

contract Lottery {
    address public owner;
    uint private latestBlockNumber;
    bytes32 private cumulativeHash;
    address[] private participants;
    mapping(address => uint256) public pendingWithdrawals;
    uint256 public ownerSharePercent = 10;
    uint256 public winnerSharePercent = 90;
    bool public splitAllowed = true;
    uint256 public gameRunCounter;
    uint256 public minEntriesRequiredPerGame = 3;
    uint256 public minEntryInWei = 0.1 ether;
    bool public isRunning = true;
    bool public autoDistributeWinnings = false;
    uint256 public potSize;
    
    event betStarted(address indexed player, uint amount);
    event betAccepted(address indexed player, uint amount, uint blockNumber);
    event betNotPlaced(address indexed player, uint amount, uint blockNumber);
    event startWinnerDraw(uint256 randomIndex, address winner, uint blockNumber, uint256 amount);
    event amountWonByOwner(address owner, uint256 amount);
    event amountWonByWinner(address winner, uint256 amount);
    event startWithDraw(address player, uint256 amount);
    event successWithDraw(address player, uint256 amount);
    event rollbackWithDraw(address player, uint256 amount);
    event showParticipants(address[] participants);
    event showBetNumber(uint256 index, address player);
    event calledConstructor(uint blockNumber, address owner);
    event successDrawWinner(bool success);
    event notReadyDrawWinner(bool notReady);
    
    constructor() public {
        owner = msg.sender;
        latestBlockNumber = block.number;
        cumulativeHash = bytes32(0);
        emit calledConstructor(latestBlockNumber, owner);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function () public payable {
        if (isRunning == true) {
            uint amount = msg.value;
            emit betStarted(msg.sender, amount);
            
            require(amount >= 0.1 ether);
            assert(amount >= minEntryInWei);
            
            cumulativeHash = keccak256(abi.encodePacked(
                blockhash(latestBlockNumber), 
                cumulativeHash
            ));
            
            emit betAccepted(msg.sender, msg.value, block.number);
            latestBlockNumber = block.number;
            participants.push(msg.sender);
            
            potSize = potSize + msg.value;
        } else {
            emit betNotPlaced(msg.sender, msg.value, block.number);
        }
        
        if (participants.length >= minEntriesRequiredPerGame) {
            bool success = drawWinner();
            emit successDrawWinner(success);
            gameRunCounter = gameRunCounter + 1;
        } else {
            emit notReadyDrawWinner(false);
        }
    }
    
    function placeBet() public payable returns (bool) {
        if (isRunning == true) {
            uint amount = msg.value;
            emit betStarted(msg.sender, amount);
            
            require(amount >= minEntryInWei);
            cumulativeHash = keccak256(abi.encodePacked(
                blockhash(latestBlockNumber), 
                cumulativeHash
            ));
            
            emit betAccepted(msg.sender, msg.value, block.number);
            latestBlockNumber = block.number;
            participants.push(msg.sender);
            potSize = potSize + msg.value;
        } else {
            emit betNotPlaced(msg.sender, msg.value, block.number);
        }
        
        if (participants.length >= minEntriesRequiredPerGame) {
            bool success = drawWinner();
            emit successDrawWinner(success);
            gameRunCounter = gameRunCounter + 1;
        } else {
            emit notReadyDrawWinner(false);
        }
        return true;
    }
    
    function drawWinner() private returns (bool) {
        bool successFlag = false;
        assert(participants.length >= minEntriesRequiredPerGame);
        
        latestBlockNumber = block.number;
        bytes32 randomHash = keccak256(abi.encodePacked(
            blockhash(latestBlockNumber - 1), 
            cumulativeHash
        ));
        
        uint256 randomInt = uint256(randomHash) % participants.length;
        address winner = participants[randomInt];
        uint256 amountWon = potSize;
        uint256 ownerAmount = amountWon * ownerSharePercent / 100;
        uint256 winnerAmount = amountWon * winnerSharePercent / 100;
        
        if (splitAllowed == true) {
            emit startWinnerDraw(randomInt, winner, latestBlockNumber, winnerAmount);
            pendingWithdrawals[winner] = winnerAmount;
            owner.transfer(ownerAmount);
            emit amountWonByOwner(owner, ownerAmount);
            
            if (autoDistributeWinnings == true) {
                pendingWithdrawals[winner] = 0;
                if (winner.send(winnerAmount)) {
                    emit successWithDraw(winner, winnerAmount);
                    emit amountWonByWinner(winner, winnerAmount);
                } else {
                    pendingWithdrawals[winner] = winnerAmount;
                    emit rollbackWithDraw(winner, winnerAmount);
                }
            }
        } else {
            emit startWinnerDraw(randomInt, winner, latestBlockNumber, amountWon);
            pendingWithdrawals[winner] = amountWon;
            
            if (autoDistributeWinnings == true) {
                pendingWithdrawals[winner] = 0;
                if (winner.send(amountWon)) {
                    emit successWithDraw(winner, amountWon);
                    emit amountWonByWinner(winner, amountWon);
                } else {
                    pendingWithdrawals[winner] = amountWon;
                    emit rollbackWithDraw(winner, amountWon);
                }
            }
        }
        
        cumulativeHash = bytes32(0);
        delete participants;
        potSize = 0;
        successFlag = true;
        return successFlag;
    }
    
    function getWinner() private onlyOwner returns (address) {
        assert(participants.length >= minEntriesRequiredPerGame);
        
        latestBlockNumber = block.number;
        bytes32 randomHash = keccak256(abi.encodePacked(
            blockhash(latestBlockNumber - 1), 
            cumulativeHash
        ));
        
        uint256 randomInt = uint256(randomHash) % participants.length;
        address winner = participants[randomInt];
        uint256 amountWon = potSize;
        uint256 ownerAmount = amountWon * ownerSharePercent / 100;
        uint256 winnerAmount = amountWon * winnerSharePercent / 100;
        
        if (splitAllowed == true) {
            pendingWithdrawals[winner] = winnerAmount;
            owner.transfer(ownerAmount);
            emit amountWonByOwner(owner, ownerAmount);
            
            if (autoDistributeWinnings == true) {
                pendingWithdrawals[winner] = 0;
                if (winner.send(winnerAmount)) {
                    emit successWithDraw(winner, winnerAmount);
                    emit amountWonByWinner(winner, winnerAmount);
                } else {
                    pendingWithdrawals[winner] = winnerAmount;
                    emit rollbackWithDraw(winner, winnerAmount);
                }
            }
        } else {
            pendingWithdrawals[winner] = amountWon;
            
            if (autoDistributeWinnings == true) {
                pendingWithdrawals[winner] = 0;
                if (winner.send(amountWon)) {
                    emit successWithDraw(winner, amountWon);
                    emit amountWonByWinner(winner, amountWon);
                } else {
                    pendingWithdrawals[winner] = amountWon;
                    emit rollbackWithDraw(winner, amountWon);
                }
            }
        }
        
        cumulativeHash = bytes32(0);
        delete participants;
        potSize = 0;
        emit startWinnerDraw(randomInt, winner, latestBlockNumber, pendingWithdrawals[winner]);
        return winner;
    }
    
    function withdraw() private returns (bool) {
        uint256 amount = pendingWithdrawals[msg.sender];
        emit startWithDraw(msg.sender, amount);
        pendingWithdrawals[msg.sender] = 0;
        
        if (msg.sender.send(amount)) {
            emit successWithDraw(msg.sender, amount);
            return true;
        } else {
            pendingWithdrawals[msg.sender] = amount;
            emit rollbackWithDraw(msg.sender, amount);
            return false;
        }
    }
    
    function getParticipants() public onlyOwner returns (address[]) {
        emit showParticipants(participants);
        return participants;
    }
    
    function toggleGameState() public onlyOwner returns (bool) {
        if (isRunning == false) {
            isRunning = true;
        } else {
            isRunning = false;
        }
        return isRunning;
    }
    
    function setMinEntries(uint256 minEntries) public onlyOwner returns (bool) {
        minEntriesRequiredPerGame = minEntries;
        return true;
    }
    
    function setMinBetAmount(uint256 minBet) public onlyOwner returns (bool) {
        minEntryInWei = minBet;
        return true;
    }
    
    function getBetNumber(uint256 index) private returns (address) {
        emit showBetNumber(index, participants[index]);
        return participants[index];
    }
    
    function getParticipantCount() public view returns (uint256) {
        return participants.length;
    }
    
    function getMinEntriesRequired() public view returns (uint256) {
        return minEntriesRequiredPerGame;
    }
    
    function destroy() onlyOwner public {
        uint256 balance = potSize;
        owner.transfer(balance);
        selfdestruct(owner);
    }
}
```