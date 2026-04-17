pragma solidity ^0.4.18;

contract Lottery {
    uint internal constant MIN_SEND_VALUE = 2000000000000000;
    uint internal constant JACKPOT_CHANCE = 2;
    uint internal constant JACKPOT_PRIZE = 5000000000000000;
    uint internal constant MAX_RANDOM = 100;
    
    uint internal participantCount;
    address internal lastWinner;
    address internal lastJackpotWinner;
    mapping(address => bool) internal hasParticipated;
    address[] internal participants;
    
    event LotteryLog(address indexed participant, string message);
    
    function Lottery() public {
        participantCount = (uint(msg.sender) + block.timestamp) % MAX_RANDOM;
    }
    
    function () public payable {
        LotteryLog(msg.sender, "Received new funds...");
        
        if (msg.value >= MIN_SEND_VALUE) {
            if (!hasParticipated[msg.sender]) {
                hasParticipated[msg.sender] = true;
                participants.push(msg.sender);
                participantCount++;
                
                uint randomIndex = uint(keccak256(block.timestamp + block.number + uint(msg.sender) + participantCount)) % participants.length;
                address winner = participants[randomIndex];
                
                uint jackpotNumber = uint(keccak256(block.timestamp + randomIndex)) % MAX_RANDOM;
                
                if (jackpotNumber < JACKPOT_CHANCE) {
                    lastJackpotWinner = winner;
                    lastJackpotWinner.transfer(msg.value + JACKPOT_PRIZE);
                    LotteryLog(lastJackpotWinner, "Jackpot is hit!");
                } else {
                    lastWinner = winner;
                    lastWinner.transfer(JACKPOT_PRIZE);
                    LotteryLog(lastWinner, "We have a Winner!");
                }
            } else {
                msg.sender.transfer(msg.value);
                LotteryLog(msg.sender, "Failed: already joined! Sending back received ether...");
            }
        } else {
            msg.sender.transfer(msg.value);
            LotteryLog(msg.sender, "Failed: not enough Ether sent! Sending back received ether...");
        }
    }
    
    function getParticipantCount() public view returns(uint) {
        return participants.length;
    }
    
    function getJackpotPrize() public view returns(uint) {
        return JACKPOT_PRIZE;
    }
    
    function getLastWinner() public view returns(address) {
        return lastWinner;
    }
    
    function getLastJackpotWinner() public view returns(address) {
        return lastJackpotWinner;
    }
}