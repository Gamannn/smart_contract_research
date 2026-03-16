pragma solidity ^0.5.3;

contract ProxyContract {
    struct AddressStorage {
        address masterCopy;
    }

    AddressStorage private addressStorage;

    constructor(address masterCopyAddress) public {
        require(masterCopyAddress != address(0), "Invalid master copy address provided");
        addressStorage.masterCopy = masterCopyAddress;
    }

    function () external payable {
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, masterCopy)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}