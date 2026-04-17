pragma solidity ^0.4.19;

contract Lottery {
    address public owner;
    uint256 public totalBounty;
    uint256 public numTickets;
    uint256 public lastTicketTime;
    uint8 public direction;
    uint256 public lottoIndex;
    uint256 public maxTickets;
    uint256 public ticketPrice;
    
    event NewTicket(address indexed buyer, bool isLast);
    event LottoComplete(address indexed winner, uint indexed lottoIndex, uint256 prize);
    
    function Lottery() public {
        owner = msg.sender;
        ticketPrice = 0.0101 * 10**18;
        maxTickets = 18;
        direction = 0;
        lottoIndex = 1;
        numTickets = 0;
        totalBounty = 0;
        lastTicketTime = 0;
    }
    
    function balance() public view returns (uint256) {
        if (owner == msg.sender) {
            return this.balance;
        }
        return 0;
    }
    
    function withdraw() public {
        require(owner == msg.sender);
        lottoIndex += 1;
        numTickets = 0;
        totalBounty = 0;
        owner.transfer(this.balance);
    }
    
    function getStats() public view returns (uint256, uint256, uint256, uint256, uint256) {
        return (numTickets, totalBounty, lastTicketTime, maxTickets, lottoIndex);
    }
    
    function buyTicket() public payable {
        require(msg.value == ticketPrice);
        require(numTickets < maxTickets);
        
        lastTicketTime = now;
        numTickets += 1;
        totalBounty += ticketPrice;
        
        bool isLast = numTickets == maxTickets;
        NewTicket(msg.sender, isLast);
        
        if (isLast) {
            payWinner(msg.sender);
        }
    }
    
    function payWinner(address winner) private {
        require(numTickets == maxTickets);
        uint256 ownerTax = totalBounty * 6 / 100;
        uint256 winnerPrize = totalBounty - ownerTax;
        
        LottoComplete(winner, lottoIndex, winnerPrize);
        
        resetValues();
        adjustMaxTickets();
        
        owner.transfer(ownerTax);
        winner.transfer(winnerPrize);
    }
    
    function resetValues() private {
        lottoIndex += 1;
        numTickets = 0;
        totalBounty = 0;
    }
    
    function adjustMaxTickets() private {
        if (direction == 0 && maxTickets < 20) {
            maxTickets += 1;
        }
        if (direction == 1 && maxTickets > 10) {
            maxTickets -= 1;
        }
        if (direction == 0 && maxTickets == 20) {
            direction = 1;
        }
        if (direction == 1 && maxTickets == 10) {
            direction = 0;
        }
    }
    
    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }
    
    uint256[] public _integer_constant = [10, 1, 6, 18, 20, 100, 0];
}