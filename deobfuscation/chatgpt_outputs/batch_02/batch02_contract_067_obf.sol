pragma solidity ^0.4.21;

contract ExternalContract {
    function execute(uint, address) payable public {
        uint;
        address;
    }
}

contract MainContract {
    modifier onlyOwner() {
        require(msg.sender == contractState.owner);
        _;
    }

    address public owner;
    ExternalContract public externalContract;
    bool public isActive;

    struct ContractState {
        bool isActive;
        address owner;
    }

    ContractState contractState = ContractState(false, address(0));

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

    function getBooleanConstant(uint256 index) internal view returns (bool) {
        return _booleanConstants[index];
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return _integerConstants[index];
    }

    bool[] public _booleanConstants = [true];
    uint256[] public _integerConstants = [31, 1000000000000000000];
}