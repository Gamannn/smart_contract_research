pragma solidity >=0.4.21 <0.7.0;

contract SimpleContract {
    address payable owner;
    event AmountEmitted(uint256 amount);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function() external payable {
        uint256 totalAmount;
        uint256 constantValue1 = 3;
        uint256 constantValue2 = 30;
        totalAmount = constantValue1 + constantValue2;
        emit AmountEmitted(totalAmount);
    }

    function destroyContract() public onlyOwner {
        selfdestruct(owner);
    }
}