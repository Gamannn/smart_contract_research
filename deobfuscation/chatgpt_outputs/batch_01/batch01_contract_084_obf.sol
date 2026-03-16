pragma solidity ^0.4.23;

contract DataStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
}

pragma solidity ^0.4.23;

contract Proxy {
    function () public payable {
        address implementation = getImplementation();
        require(implementation != address(0));
        bytes memory data = msg.data;
        assembly {
            let result := delegatecall(gas, implementation, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function getImplementation() public view returns (address);
}

pragma solidity ^0.4.23;

contract ImplementationStorage {
    function getVersion() public view returns (string) {
        return storageData.version;
    }

    function getImplementation() public view returns (address) {
        return storageData.implementation;
    }
}

pragma solidity ^0.4.23;

contract Upgradeable is Proxy, ImplementationStorage {
    event Upgraded(string version, address indexed implementation);

    function upgradeTo(string version, address implementation) internal {
        require(storageData.implementation != implementation);
        storageData.version = version;
        storageData.implementation = implementation;
        emit Upgraded(version, implementation);
    }
}

pragma solidity ^0.4.23;

contract OwnerStorage {
    function getOwner() public view returns (address) {
        return storageData.owner;
    }

    function setOwner(address newOwner) internal {
        storageData.owner = newOwner;
    }
}

pragma solidity ^0.4.23;

contract OwnedUpgradeable is OwnerStorage, Upgradeable {
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    function OwnedUpgradeable(address initialOwner) public {
        setOwner(initialOwner);
    }

    modifier onlyOwner() {
        require(msg.sender == getOwner());
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit ProxyOwnershipTransferred(getOwner(), newOwner);
        setOwner(newOwner);
    }

    function upgradeToAndCall(string version, address implementation, bytes data) payable public onlyOwner {
        upgradeTo(version, implementation);
        require(this.call.value(msg.value)(data));
    }
}

pragma solidity ^0.4.23;

contract MainContract is OwnedUpgradeable, DataStorage {
    function MainContract(address initialOwner) public OwnedUpgradeable(initialOwner) {}

    struct StorageData {
        address owner;
        address implementation;
        string version;
    }

    StorageData storageData = StorageData(address(0), address(0), "");
}