```solidity
pragma solidity ^0.4.2;

contract Ownable {
    address public owner;
    
    function Ownable() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract LuxuryToken is Ownable {
    string public name = "Luxury Token";
    string public symbol = "LUX";
    uint8 public decimals = 0;
    uint256 public issuePrice = 1;
    bool public isAllowedToPurchase = false;
    uint256 public minTokensRequiredForMessage = 10;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => string) public messages;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event MessageAdded(address indexed from, string message, uint256 balance);
    
    function LuxuryToken() {
    }
    
    function transfer(address to, uint256 value) returns (bool success) {
        if (value == 0) {
            return false;
        }
        if (balanceOf[msg.sender] < value) {
            return false;
        }
        if (balanceOf[to] + value < balanceOf[to]) {
            return false;
        }
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }
    
    function enablePurchasing() onlyOwner {
        isAllowedToPurchase = true;
    }
    
    function disablePurchasing() onlyOwner {
        isAllowedToPurchase = false;
    }
    
    function() payable {
        require(isAllowedToPurchase);
        uint256 amount = msg.value / issuePrice;
        balanceOf[msg.sender] += amount;
        Transfer(address(this), msg.sender, amount);
    }
    
    function getBalance(address account) constant returns(uint256) {
        return balanceOf[account];
    }
    
    function issueTokens(address recipient, uint256 amount) onlyOwner {
        recipient.transfer(amount);
    }
    
    function setIssuePrice(uint256 price) onlyOwner {
        issuePrice = price;
    }
    
    function setSymbol(string newSymbol) onlyOwner {
        symbol = newSymbol;
    }
    
    function addMessage(string message) {
        uint256 userBalance = balanceOf[msg.sender];
        require(userBalance >= minTokensRequiredForMessage);
        MessageAdded(msg.sender, message, userBalance);
    }
}
```