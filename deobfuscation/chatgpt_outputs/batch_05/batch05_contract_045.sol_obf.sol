pragma solidity 0.5.10;

contract ProxyContract {
    address public implementation;
    bool public isPayable;

    event LogImplementationChanged(address oldImplementation, address newImplementation);
    event LogPaymentReceived(address sender, uint256 amount);

    struct ImplementationDetails {
        bool isPayable;
        address implementation;
    }

    ImplementationDetails internal details = ImplementationDetails(false, address(0));

    constructor(address initialImplementation, bool initialIsPayable) public {
        require(initialImplementation != address(0), "Implementation address cannot be 0");
        details.implementation = initialImplementation;
        details.isPayable = initialIsPayable;
    }

    modifier onlyImplementation() {
        require(msg.sender == details.implementation, "Only the implementation may perform this action");
        _;
    }

    function withdrawBalance() external onlyImplementation {
        msg.sender.call.value(address(this).balance)("");
    }

    function () external payable {
        emit LogPaymentReceived(msg.sender, msg.value);
    }

    uint256[] public integerConstants = [0];
    string[] public stringConstants = ["", "Implementation address cannot be 0", "Only the contract implementation may perform this action"];

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return integerConstants[index];
    }

    function getStringConstant(uint256 index) internal view returns (string storage) {
        return stringConstants[index];
    }
}