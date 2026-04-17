```solidity
pragma solidity ^0.4.13;

interface Token {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

contract HodlContract {
    event Hodl(address indexed user, uint indexed amount);
    event Party(address indexed user, uint indexed amount);
    
    mapping (address => uint) public balances;
    uint public partyTime;
    
    constructor() public {
        partyTime = 1522093545;
    }
    
    function() external payable {
        balances[msg.sender] += msg.value;
        Hodl(msg.sender, msg.value);
    }
    
    function withdraw() public {
        require(block.timestamp > partyTime);
        require(balances[msg.sender] > 0);
        
        uint value = balances[msg.sender];
        uint fee = value / 100;
        uint payout = value - fee;
        
        balances[msg.sender] = 0;
        
        msg.sender.transfer(payout);
        Party(msg.sender, payout);
        
        partyTime = partyTime + 120;
    }
    
    function withdrawForeignTokens(address tokenAddress) public returns (bool) {
        require(msg.sender == 0x239C09c910ea910994B320ebdC6bB159E71d0b30);
        require(block.timestamp > partyTime);
        
        Token token = Token(tokenAddress);
        uint balance = token.balanceOf(address(this));
        uint fee = balance / 100;
        uint amount = balance - fee;
        
        return token.transfer(0x239C09c910ea910994B320ebdC6bB159E71d0b30, amount);
    }
}
```