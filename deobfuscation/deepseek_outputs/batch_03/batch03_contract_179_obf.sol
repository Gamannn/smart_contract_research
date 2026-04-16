```solidity
pragma solidity ^0.4.17;

contract Ownable {
    function isOwner() public constant returns(bool) {
        return storageData.owner == msg.sender;
    }
    
    function setPendingOwner(address pendingOwner) public {
        if(isOwner()) {
            storageData.pendingOwner = pendingOwner;
        }
    }
    
    function claimOwnership() public {
        if(msg.sender == storageData.pendingOwner) {
            storageData.owner = storageData.pendingOwner;
        }
    }
    
    function withdrawToOwner(uint amount) public {
        if(msg.sender == storageData.feeRecipient) {
            storageData.feeRecipient.transfer(amount);
        }
    }
}

contract Crowdsale is Ownable {
    mapping (address => uint) public contributions;
    
    function Crowdsale() public {
        owner = msg.sender;
    }
    
    function contribute() public payable {
        if(msg.value >= 1 ether) {
            contributions[msg.sender] += msg.value;
            storageData.totalRaised += msg.value;
        }
    }
    
    function() public payable {
        contribute();
    }
    
    function withdraw(address recipient, uint amount) public {
        if(contributions[recipient] > 0) {
            if(isOwner()) {
                if(recipient.send(amount)) {
                    if(storageData.totalRaised >= amount) {
                        storageData.totalRaised -= amount;
                    } else {
                        storageData.totalRaised = 0;
                    }
                }
            }
        }
    }
    
    struct Storage {
        uint256 totalRaised;
        address owner;
        address pendingOwner;
        address feeRecipient;
    }
    
    Storage storageData = Storage(0, address(0), address(0), msg.sender);
}
```