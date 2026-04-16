```solidity
pragma solidity ^0.4.24;

contract Lottery {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier notPooh(address aContract) {
        require(aContract != address(poohContract));
        _;
    }
    
    modifier isOpenToPublic() {
        require(openToPublic);
        _;
    }
    
    event Deposit(
        uint256 amount,
        address depositer
    );
    
    event WinnerPaid(
        uint256 amount,
        address winner
    );
    
    POOH public poohContract;
    address public owner;
    bool public openToPublic = false;
    
    uint256 public winningNumber;
    uint256 public ticketNumber;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function() payable public {
    }
    
    function deposit() isOpenToPublic() payable public {
        require(msg.value >= 10000000000000000);
        
        address customerAddress = msg.sender;
        poohContract.buy.value(msg.value)(customerAddress);
        
        emit Deposit(msg.value, msg.sender);
        
        if(msg.value > 10000000000000000) {
            uint256 extraTickets = SafeMath.div(msg.value, 10000000000000000);
            ticketNumber += extraTickets;
        }
        
        if(ticketNumber == winningNumber) {
            payDev(owner);
            payWinner(customerAddress);
        } else {
            ticketNumber++;
        }
    }
    
    function myTokens() public view returns(uint256) {
        return poohContract.myTokens();
    }
    
    function myDividends() public view returns(uint256) {
        return poohContract.myDividends(true);
    }
    
    function ethBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function openToThePublic() onlyOwner() public {
        openToPublic = true;
        resetLottery();
    }
    
    function returnAnyERC20Token(address tokenAddress, address tokenOwner, uint256 tokens) 
        public 
        onlyOwner() 
        notPooh(tokenAddress) 
        returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
    
    function payWinner(address winner) internal {
        uint256 balance = SafeMath.sub(address(this).balance, 50000000000000000);
        winner.transfer(balance);
        emit WinnerPaid(balance, winner);
    }
    
    function payDev(address dev) internal {
        uint256 balance = SafeMath.div(address(this).balance, 10);
        dev.transfer(balance);
    }
    
    function resetLottery() internal isOpenToPublic() {
        ticketNumber = 1;
        winningNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 300;
    }
}

interface ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

interface POOH {
    function buy(address) public payable returns(uint256);
    function exit() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
}

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}
```