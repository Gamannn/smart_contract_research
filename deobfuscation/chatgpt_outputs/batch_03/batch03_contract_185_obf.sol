pragma solidity 0.4.23;

contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
}

pragma solidity 0.4.23;

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

pragma solidity 0.4.23;

contract UpgradeabilityStorage {
    function getVersion() public view returns (string) {
        return storageData.version;
    }

    function getImplementation() public view returns (address) {
        return storageData.implementation;
    }

    struct StorageData {
        address implementation;
        string version;
    }

    StorageData storageData;
}

pragma solidity 0.4.23;

contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage {
    event Upgraded(string version, address indexed implementation);

    function upgradeTo(string version, address implementation) internal {
        require(storageData.implementation != implementation);
        storageData.version = version;
        storageData.implementation = implementation;
        emit Upgraded(version, implementation);
    }
}

pragma solidity 0.4.23;

contract OwnedUpgradeabilityStorage {
    function getOwner() public view returns (address) {
        return storageData.owner;
    }

    function setOwner(address newOwner) internal {
        storageData.owner = newOwner;
    }

    struct StorageData {
        address owner;
    }

    StorageData storageData;
}

pragma solidity 0.4.23;

contract OwnedUpgradeabilityProxy is OwnedUpgradeabilityStorage, UpgradeabilityProxy {
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    constructor(address owner) public {
        setOwner(owner);
    }

    modifier onlyProxyOwner() {
        require(msg.sender == getOwner());
        _;
    }

    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0));
        emit ProxyOwnershipTransferred(getOwner(), newOwner);
        setOwner(newOwner);
    }

    function upgradeTo(string version, address implementation) public onlyProxyOwner {
        upgradeTo(version, implementation);
    }

    function upgradeToAndCall(string version, address implementation, bytes data) payable public onlyProxyOwner {
        upgradeTo(version, implementation);
        require(address(this).call.value(msg.value)(data));
    }
}

pragma solidity 0.4.23;

/**
 * @title EternalStorageProxy
 * @dev This proxy holds the storage of the token contract and delegates every call to the current implementation set.
 * Besides, it allows to upgrade the token's behaviour towards further implementations, and provides basic
 * authorization control functionalities
 */
contract EternalStorageProxy is OwnedUpgradeabilityProxy, EternalStorage {
    constructor(address owner) public OwnedUpgradeabilityProxy(owner) {}
}