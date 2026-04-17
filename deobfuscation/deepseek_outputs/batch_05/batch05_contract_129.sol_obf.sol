pragma solidity ^0.4.20;

contract Oxee62e5df981f240f264ab3fb6bbc67337ce49216 {
    address[][] public participants;
    mapping(address => uint) public balances;
    
    address public owner = 0x5372260584003e8Ae3a24E9dF09fa96037a04c2b;
    bool public isPaused = false;
    
    function getRoundCount() public view returns (uint) {
        return participants.length;
    }
    
    function getParticipantCount(uint roundIndex) public view returns (uint) {
        return participants[roundIndex].length;
    }
    
    function calculateEntryFee(uint level) public pure returns(uint) {
        return 0.005 ether * (uint(2)**level);
    }
    
    function setPaused(bool pauseStatus) public {
        require(msg.sender == owner);
        isPaused = pauseStatus;
    }
    
    function joinRound(uint roundIndex, uint level) public payable {
        balances[msg.sender] += msg.value;
        uint entryFee = calculateEntryFee(level);
        
        require(balances[msg.sender] >= entryFee);
        balances[msg.sender] -= entryFee;
        
        if(roundIndex == participants.length) {
            require(isPaused == false);
            participants.length++;
        } else if (roundIndex > participants.length) {
            revert();
        }
        
        require(level == participants[roundIndex].length);
        participants[roundIndex].push(msg.sender);
        
        if(level == 0) {
            balances[owner] += entryFee;
        } else {
            address previousParticipant = participants[roundIndex][level - 1];
            balances[previousParticipant] += entryFee * 99 / 100;
            balances[owner] += entryFee * 1 / 100;
        }
    }
    
    function withdraw() public {
        msg.sender.transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }
}