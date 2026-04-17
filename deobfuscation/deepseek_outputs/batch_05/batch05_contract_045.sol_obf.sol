pragma solidity 0.5.10;

contract Ox926e3e3b78e9ee38ba161be3369a7260c67c7f35 {
    address public implementation;
    bool public isPaused;
    
    event LogImplementationChanged(address indexed oldImplementation, address indexed newImplementation);
    event LogPaymentReceived(address indexed sender, uint256 amount);

    constructor(address _implementation, bool _isPaused) public {
        require(_implementation != address(0), "Implementation address cannot be 0");
        implementation = _implementation;
        isPaused = _isPaused;
    }

    modifier onlyImplementation() {
        require(msg.sender == implementation, "Only the implementation may perform this action");
        _;
    }

    function withdraw() external onlyImplementation {
        msg.sender.call.value(address(this).balance)("");
    }

    function () external payable {
        emit LogPaymentReceived(msg.sender, msg.value);
    }
}