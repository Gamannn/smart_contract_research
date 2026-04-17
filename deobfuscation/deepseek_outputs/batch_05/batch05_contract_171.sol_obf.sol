pragma solidity ^0.4.18;

contract Lottery {
    uint internal participantCount;
    uint internal jackpotChance;
    uint internal jackpotNumber;
    uint internal randomSeed;
    address internal lastWinner;
    address internal lastJackpotWinner;
    mapping(address => bool) public hasParticipated;
    address[] public participants;
    uint public jackpotBalance;
    uint public constant MIN_SEND_VAL = 2000000000000000;
    uint public constant JACKPOT_CHANCE = 2;
    uint public constant JACKPOT_MIN = 5000000000000000;
    uint public constant MAX_PARTICIPANTS = 100;
    
    event LotteryLog(address indexed participant, string message);
    
    function Lottery() public {
        randomSeed = (uint(msg.sender) + block.timestamp) % 100;
    }
    
    function () public payable {
        LotteryLog(msg.sender, "Received new funds...");
        
        if(msg.value >= MIN_SEND_VAL) {
            if(hasParticipated[msg.sender] == false) {
                hasParticipated[msg.sender] = true;
                participants.push(msg.sender);
                randomSeed++;
                
                uint winnerIndex = uint(keccak256(block.timestamp + block.number + uint(msg.sender) + randomSeed)) % participants.length;
                address winner = participants[winnerIndex];
                
                jackpotNumber = uint(keccak256(block.timestamp + winnerIndex)) % 100;
                
                if(jackpotNumber < JACKPOT_CHANCE) {
                    lastJackpotWinner = winner;
                    lastJackpotWinner.transfer(msg.value + jackpotBalance);
                    jackpotBalance = 0;
                    LotteryLog(lastJackpotWinner, "Jackpot is hit!");
                }
                
                jackpotBalance += msg.value;
                winner.transfer(msg.value);
                lastWinner = winner;
                LotteryLog(winner, "We have a Winner!");
            } else {
                msg.sender.transfer(msg.value);
                LotteryLog(msg.sender, "Failed: already joined! Sending back received ether...");
            }
        } else {
            msg.sender.transfer(msg.value);
            LotteryLog(msg.sender, "Failed: not enough Ether sent! Sending back received ether...");
        }
    }
    
    function getParticipantCount() public constant returns(uint) {
        return participants.length;
    }
    
    function getJackpotBalance() public constant returns(uint) {
        return jackpotBalance;
    }
    
    function getLastWinner() public constant returns(address) {
        return lastWinner;
    }
    
    function getLastJackpotWinner() public constant returns(address) {
        return lastJackpotWinner;
    }
}