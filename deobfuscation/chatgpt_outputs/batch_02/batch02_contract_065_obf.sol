pragma solidity ^0.4.21;

contract PaymentReceiver {
    function receivePayment(uint amount, address sender) payable public {
        uint; // Placeholder, no functionality
        address; // Placeholder, no functionality
    }
}

contract PaymentManager {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;
    PaymentReceiver public paymentReceiver;
    bool public isActive;

    struct Config {
        bool isActive;
        address owner;
    }

    Config config = Config(false, address(0));

    function PaymentManager(address initialOwner) public {
        owner = initialOwner;
    }

    function setPaymentReceiver(address receiverAddress) public onlyOwner {
        paymentReceiver = PaymentReceiver(receiverAddress);
    }

    function setActive(bool active) public onlyOwner {
        isActive = active;
    }

    function () payable public {
        if (isActive) {
            require(msg.value == getIntegerConstant(0));
            paymentReceiver.receivePayment(getIntegerConstant(1), msg.sender);
        } else {
            return;
        }
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return _integerConstants[index];
    }

    function getBoolConstant(uint256 index) internal view returns (bool) {
        return _boolConstants[index];
    }

    uint256[] public _integerConstants = [100000000000000000, 76];
    bool[] public _boolConstants = [true];
}