pragma solidity ^0.4.21;

contract ExternalContract {
    function execute(uint amount, address sender) payable public {
        uint; address;
    }
}

contract MainContract {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;
    ExternalContract public externalContract;
    bool public isActive;

    struct State {
        bool isActive;
        address owner;
    }

    State state = State(false, address(0));

    function setExternalContract(address contractAddress) public onlyOwner {
        externalContract = ExternalContract(contractAddress);
    }

    function setActive(bool active) public onlyOwner {
        isActive = active;
    }

    function () payable public {
        if (isActive) {
            require(msg.value == getIntegerConstant(1));
            externalContract.execute(getIntegerConstant(0), msg.sender);
        } else {
            return;
        }
    }

    function getIntegerConstant(uint256 index) internal view returns(uint256) {
        return integerConstants[index];
    }

    function getBooleanConstant(uint256 index) internal view returns(bool) {
        return booleanConstants[index];
    }

    uint256[] public integerConstants = [16, 500000000000000000];
    bool[] public booleanConstants = [true];
}