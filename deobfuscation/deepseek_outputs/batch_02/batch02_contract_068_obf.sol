```solidity
pragma solidity ^0.4.21;

contract PaymentReceiver {
    function receivePayment(uint, address) payable {}
}

contract MainContract {
    address public owner;
    PaymentReceiver public paymentReceiver;
    bool public isActive;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function MainContract() public {
        owner = msg.sender;
        isActive = false;
    }
    
    function setPaymentReceiver(address _receiver) public onlyOwner {
        paymentReceiver = PaymentReceiver(_receiver);
    }
    
    function setActive(bool _active) public onlyOwner {
        isActive = _active;
    }
    
    function() payable {
        if (isActive == true) {
            require(msg.value == 500000000000000000);
            paymentReceiver.receivePayment(16, msg.sender);
        } else {
            revert();
        }
    }
}
```