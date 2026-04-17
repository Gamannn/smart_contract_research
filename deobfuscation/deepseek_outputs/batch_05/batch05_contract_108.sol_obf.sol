```solidity
pragma solidity ^0.4.15;

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract EthMessage is Ownable {
    uint public constant BASEPRICE = 0.01 ether;
    uint public constant MAX_MESSAGE_LENGTH = 255;
    
    string public currentMessage;
    uint public currentPrice;
    
    function EthMessage() {
        currentPrice = BASEPRICE;
    }
    
    function resetMessage() onlyOwner public {
        currentMessage = "";
    }
    
    modifier payRequiredPrice() {
        require(msg.value >= currentPrice);
        if (msg.value > currentPrice) {
            msg.sender.transfer(msg.value - currentPrice);
        }
        currentPrice += BASEPRICE;
        _;
    }
    
    function setMessage(string messageToPost) payRequiredPrice payable {
        if (bytes(messageToPost).length > MAX_MESSAGE_LENGTH) {
            revert();
        }
        currentMessage = messageToPost;
    }
    
    function() {
        revert();
    }
}
```