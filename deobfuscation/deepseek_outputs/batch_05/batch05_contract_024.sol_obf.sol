```solidity
pragma solidity ^0.4.11;

contract Ownable {
    address public owner;
    
    function Ownable() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract TextContract is Ownable {
    uint public cost;
    bool public enabled;
    
    event NewText(string phone, string text);
    event UpdateCost(uint newCost);
    event UpdateEnabled(string status);
    
    function TextContract() {
        cost = 380000000000000;
        enabled = true;
    }
    
    function changeCost(uint newCost) onlyOwner {
        cost = newCost;
        UpdateCost(cost);
    }
    
    function disable() onlyOwner {
        enabled = false;
        UpdateEnabled("Texting has been disabled");
    }
    
    function enable() onlyOwner {
        enabled = true;
        UpdateEnabled("Texting has been enabled");
    }
    
    function withdraw() onlyOwner {
        owner.transfer(this.balance);
    }
    
    function getCost() constant returns (uint) {
        return cost;
    }
    
    function sendText(string phone, string text) public payable {
        if (!enabled) throw;
        if (msg.value < cost) throw;
        
        NewText(phone, text);
    }
}
```