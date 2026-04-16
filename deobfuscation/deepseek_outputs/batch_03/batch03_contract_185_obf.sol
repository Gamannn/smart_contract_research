```solidity
pragma solidity 0.4.23;

contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
}

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

contract ImplementationInfo {
    function getVersion() public view returns (string) {
        return storageAndContext.version;
    }
    
    function getImplementation() public view returns (address) {
        return storageAndContext.implementation;
    }
    
    struct StorageContext {
        address owner;
        address implementation;
        string version;
    }
    
    StorageContext storageAndContext = StorageContext(address(0), address(0), "");
}

contract UpgradeableProxy is Proxy, ImplementationInfo {
    event Upgraded(string version, address indexed implementation);
    
    function upgradeTo(string version, address implementation) internal {
        require(storageAndContext.implementation != implementation);
        storageAndContext.version = version;
        storageAndContext.implementation = implementation;
        emit Upgraded(version, implementation);
    }
}

contract OwnableStorage {
    function getOwner() public view returns (address) {
        return storageAndContext.owner;
    }
    
    function setOwner(address newOwner) internal {
        storageAndContext.owner = newOwner;
    }
}

contract OwnableUpgradeableProxy is OwnableStorage, UpgradeableProxy {
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);
    
    constructor(address initialOwner) public {
        setOwner(initialOwner);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }
    
    function owner() public view returns (address) {
        return getOwner();
    }
    
    function transferProxyOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit ProxyOwnershipTransferred(owner(), newOwner);
        setOwner(newOwner);
    }
    
    function upgrade(string version, address implementation) public onlyOwner {
        upgradeTo(version, implementation);
    }
    
    function upgradeAndCall(string version, address implementation, bytes data) payable public onlyOwner {
        upgrade(version, implementation);
        require(address(this).call.value(msg.value)(data));
    }
}

contract EternalStorageProxy is OwnableUpgradeableProxy, EternalStorage {
    constructor(address initialOwner) public OwnableUpgradeableProxy(initialOwner) {}
}
```