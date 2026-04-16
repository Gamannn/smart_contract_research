```solidity
pragma solidity ^0.4.24;

contract Authority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) public view returns (bool);
}

contract Events {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}

contract DSAuth is Events {
    Authority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address newOwner) public auth {
        owner = newOwner;
        emit LogSetOwner(owner);
    }

    function setAuthority(Authority newAuthority) public auth {
        authority = newAuthority;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == Authority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

contract NameRegistry is DSAuth {
    uint public namePrice = 10 finney;
    
    mapping(bytes32 => address) internal nameToAddress;
    mapping(address => string) public addressToName;
    mapping(bytes32 => bool) internal pendingTransfers;
    
    modifier nameAvailable(string memory name) {
        require(!isNameTaken(name), "Name taken!");
        _;
    }
    
    modifier enoughValue() {
        require(msg.value >= namePrice, "Not enough value sent!");
        _;
    }
    
    modifier validNameLength(string memory name) {
        require(bytes(name).length <= 32, "Name too long!");
        require(bytes(name).length >= 1, "Name too short!");
        _;
    }
    
    event NameSet(address indexed addr, string name);
    event NameUnset(address indexed addr);
    event NameTransferRequested(address indexed from, address indexed to, string name);
    event NameTransferAccepted(address indexed to, string name);
    
    function isNameTaken(string memory name) public view returns(bool) {
        return nameToAddress[stringToBytes32(name)] != address(0x0) || 
               pendingTransfers[stringToBytes32(name)];
    }
    
    function hasName(address addr) public view returns(bool) {
        return bytes(addressToName[addr]).length > 0;
    }
    
    function getNameOwner(string memory name) public view returns(address) {
        return nameToAddress[stringToBytes32(name)];
    }
    
    function registerName(string memory name) 
        public 
        payable 
        nameAvailable(name)
        validNameLength(name)
        enoughValue 
    {
        addressToName[msg.sender] = name;
        nameToAddress[stringToBytes32(name)] = msg.sender;
        emit NameSet(msg.sender, name);
    }
    
    function unregisterName() public {
        nameToAddress[stringToBytes32(addressToName[msg.sender])] = address(0x0);
        addressToName[msg.sender] = "";
        emit NameUnset(msg.sender);
    }
    
    function requestNameTransfer(address to) public payable enoughValue {
        require(hasName(msg.sender), "You don't have a name to transfer!");
        addressToName[to] = addressToName[msg.sender];
        pendingTransfers[stringToBytes32(addressToName[msg.sender])] = true;
        emit NameTransferRequested(msg.sender, to, addressToName[msg.sender]);
        addressToName[msg.sender] = "";
    }
    
    function acceptNameTransfer() public validNameLength(addressToName[msg.sender]) {
        addressToName[msg.sender] = addressToName[msg.sender];
        nameToAddress[stringToBytes32(addressToName[msg.sender])] = msg.sender;
        pendingTransfers[stringToBytes32(addressToName[msg.sender])] = false;
        addressToName[msg.sender] = "";
        emit NameTransferAccepted(msg.sender, addressToName[msg.sender]);
    }
    
    function withdraw() public auth {
        owner.transfer(address(this).balance);
    }
    
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory temp = bytes(source);
        if (temp.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
}
```