```solidity
pragma solidity ^0.4.19;

contract Lottery {
    address public owner;
    uint public ticketPrice;
    string public status;
    uint public ticketsRemaining;
    address public ticket1;
    address public ticket2;
    address public ticket3;
    address public ticket4;
    address public ticket5;
    bool public locked;
    uint public seedBlockOffset;
    uint public randomNumber;
    address public lastWinner;
    uint public prizePool;
    
    constructor() public {
        owner = msg.sender;
        ticketPrice = 0.01 ether;
        status = "Running";
        ticketsRemaining = 5;
        locked = false;
        seedBlockOffset = 0;
    }
    
    function setStatus(string memory newStatus) public {
        if (msg.sender == owner) {
            status = newStatus;
        } else {
            revert();
        }
    }
    
    function setSeedBlockOffset(uint32 offset) public {
        if (msg.sender == owner) {
            seedBlockOffset = uint(offset);
        } else {
            revert();
        }
    }
    
    function () public payable {
        buyTicket();
    }
    
    function buyTicket() public payable {
        if (locked == true) {
            revert();
        }
        
        locked = true;
        
        if (msg.value != ticketPrice) {
            locked = false;
            if (keccak256(bytes(status)) == keccak256(bytes("Shutdown"))) {
                selfdestruct(owner);
            }
            revert();
        } else {
            if (ticketsRemaining == 5) {
                ticketsRemaining -= 1;
                ticket1 = msg.sender;
            } else if (ticketsRemaining == 4) {
                ticketsRemaining -= 1;
                ticket2 = msg.sender;
                owner.transfer(ticketPrice * 1/2);
            } else if (ticketsRemaining == 3) {
                ticketsRemaining -= 1;
                ticket3 = msg.sender;
            } else if (ticketsRemaining == 2) {
                ticketsRemaining -= 1;
                ticket4 = msg.sender;
            } else if (ticketsRemaining == 1) {
                ticket5 = msg.sender;
                ticketsRemaining = 5;
                
                seedBlockOffset = uint(block.blockhash(block.number - seedBlockOffset)) % 2000 + 1;
                randomNumber = uint(block.blockhash(block.number - seedBlockOffset + 1));
                prizePool = (ticketPrice * 9/2);
                
                if (randomNumber % 5 == 1) {
                    ticket1.transfer(prizePool);
                    lastWinner = ticket1;
                } else if (randomNumber % 5 == 2) {
                    ticket2.transfer(prizePool);
                    lastWinner = ticket2;
                } else if (randomNumber % 5 == 3) {
                    ticket3.transfer(prizePool);
                    lastWinner = ticket3;
                } else if (randomNumber % 5 == 4) {
                    ticket4.transfer(prizePool);
                    lastWinner = ticket4;
                } else if (randomNumber % 5 == 5) {
                    ticket5.transfer(prizePool);
                    lastWinner = ticket5;
                }
            }
        }
        
        locked = false;
    }
}
```