pragma solidity ^0.4.21;

contract PaymentProcessor {
    function processPayment(uint amount, address sender) payable public {
        uint; // Placeholder for obfuscation
        address; // Placeholder for obfuscation
    }
}

contract MainContract {
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    address public owner;
    PaymentProcessor public paymentProcessor;
    bool public isActive;

    struct ContractState {
        bool isActive;
        address owner;
    }

    ContractState state = ContractState(false, address(0));

    function MainContract(address initialOwner) public {
        owner = initialOwner;
    }

    function setPaymentProcessor(address processorAddress) public onlyOwner {
        paymentProcessor = PaymentProcessor(processorAddress);
    }

    function setActive(bool active) public onlyOwner {
        isActive = active;
    }

    function () payable public {
        if (isActive) {
            require(msg.value == getIntegerConstant(0));
            paymentProcessor.processPayment(getIntegerConstant(1), msg.sender);
        } else {
            return;
        }
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return integerConstants[index];
    }

    function getBoolConstant(uint256 index) internal view returns (bool) {
        return boolConstants[index];
    }

    uint256[] public integerConstants = [200000000000000000, 51];
    bool[] public boolConstants = [true];
}