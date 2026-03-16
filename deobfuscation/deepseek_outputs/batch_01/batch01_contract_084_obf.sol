```solidity
pragma solidity ^0.4.23;

contract Storage {
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

contract VersionInfo {
    function getVersion() public view returns (string) {
        return state.version;
    }
    
    function getImplementation() public view returns (address) {
        return state.implementation;
    }
}

contract Upgradable is Proxy, VersionInfo {
    event Upgraded(string version, address indexed implementation);
    
    function upgrade(string version, address implementation) internal {
        require(state.implementation != implementation);
        state.version = version;
        state.implementation = implementation;
        Upgraded(version, implementation);
    }
}

contract OwnableStorage {
    function getOwner() public view returns (address) {
        return state.owner;
    }
    
    function setOwner(address newOwner) internal {
        state.owner = newOwner;
    }
}

contract OwnableUpgradableProxy is OwnableStorage, Upgradable {
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);
    
    function OwnableUpgradableProxy(address initialOwner) public {
        setOwner(initialOwner);
    }
    
    modifier onlyOwner() {
        require(msg.sender == getOwner());
        _;
    }
    
    function getOwner() public view returns (address) {
        return super.getOwner();
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        ProxyOwnershipTransferred(getOwner(), newOwner);
        setOwner(newOwner);
    }
    
    function upgradeTo(string version, address implementation) public onlyOwner {
        upgrade(version, implementation);
    }
    
    function upgradeToAndCall(string version, address implementation, bytes data) payable public onlyOwner {
        upgradeTo(version, implementation);
        require(this.call.value(msg.value)(data));
    }
}

contract EternalStorageProxy is OwnableUpgradableProxy, Storage {
    function EternalStorageProxy(address initialOwner) public OwnableUpgradableProxy(initialOwner) {}
    
    struct State {
        address owner;
        address implementation;
        string version;
    }
    
    State state = State(address(0), address(0), "");
}
```