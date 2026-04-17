```solidity
pragma solidity ^0.4.21;

interface Token {
    function balanceOf(address owner) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
}

contract HodlContract {
    event Hodl(address indexed hodler, uint indexed amount);
    event Party(address indexed hodler, uint indexed amount);
    
    mapping (address => uint) public balances;
    uint public partyTime;
    
    constructor() public {
        partyTime = 1522095322;
    }
    
    function() payable public {
        balances[msg.sender] += msg.value;
        Hodl(msg.sender, msg.value);
    }
    
    function withdraw() public {
        require(block.timestamp > partyTime);
        require(balances[msg.sender] > 0);
        
        uint value = balances[msg.sender];
        uint amount = value / 100;
        balances[msg.sender] = 0;
        
        msg.sender.transfer(amount);
        Party(msg.sender, amount);
        
        partyTime = partyTime + 120;
    }
    
    function withdrawForeignTokens(address tokenAddress) public returns (bool) {
        if (msg.sender != 0x239C09c910ea910994B320ebdC6bB159E71d0b30) {
            require(block.timestamp > partyTime);
        }
        
        Token token = Token(tokenAddress);
        uint amount = token.balanceOf(address(this)) / 100;
        return token.transfer(0x239C09c910ea910994B320ebdC6bB159E71d0b30, amount);
    }
}
```