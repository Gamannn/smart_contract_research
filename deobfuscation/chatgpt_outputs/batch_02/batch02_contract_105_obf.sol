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

contract Auth is Events {
    Authority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address newOwner) public onlyAuthorized {
        owner = newOwner;
        emit LogSetOwner(owner);
    }

    function setAuthority(Authority newAuthority) public onlyAuthorized {
        authority = newAuthority;
        emit LogSetAuthority(authority);
    }

    modifier onlyAuthorized() {
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

contract NameRegistry is Auth {
    uint public registrationFee = 10 finney;
    mapping(address => string) public names;
    mapping(bytes32 => address) internal nameToAddress;
    mapping(bytes32 => bool) internal pendingTransfers;
    mapping(address => string) public pendingNameTransfers;

    modifier nameNotTaken(string name) {
        require(!isNameTaken(name), "Name taken!");
        _;
    }

    modifier hasPaidEnough() {
        require(msg.value >= registrationFee, "Not enough value sent!");
        _;
    }

    modifier validNameLength(string name) {
        require(bytes(name).length <= 32, "Name too long!");
        require(bytes(name).length >= 1, "Name too short!");
        _;
    }

    event NameSet(address indexed owner, string name);
    event NameUnset(address indexed owner);
    event NameTransferRequested(address indexed from, address indexed to, string name);
    event NameTransferAccepted(address indexed to, string name);

    function isNameTaken(string name) public view returns (bool) {
        return nameToAddress[keccak256(abi.encodePacked(name))] != address(0) || pendingTransfers[keccak256(abi.encodePacked(name))];
    }

    function hasName(address owner) public view returns (bool) {
        return bytes(names[owner]).length > 0;
    }

    function getNameOwner(string name) public view returns (address) {
        return nameToAddress[keccak256(abi.encodePacked(name))];
    }

    function registerName(string name) public payable nameNotTaken(name) validNameLength(name) hasPaidEnough {
        names[msg.sender] = name;
        nameToAddress[keccak256(abi.encodePacked(name))] = msg.sender;
        emit NameSet(msg.sender, name);
    }

    function unregisterName() public {
        nameToAddress[keccak256(abi.encodePacked(names[msg.sender]))] = address(0);
        names[msg.sender] = "";
        emit NameUnset(msg.sender);
    }

    function requestNameTransfer(address to) public payable hasPaidEnough {
        require(hasName(msg.sender), "You don't have a name to transfer!");
        pendingNameTransfers[to] = names[msg.sender];
        pendingTransfers[keccak256(abi.encodePacked(names[msg.sender]))] = true;
        emit NameTransferRequested(msg.sender, to, names[msg.sender]);
        names[msg.sender] = "";
    }

    function acceptNameTransfer() public {
        string storage name = pendingNameTransfers[msg.sender];
        names[msg.sender] = name;
        nameToAddress[keccak256(abi.encodePacked(name))] = msg.sender;
        pendingTransfers[keccak256(abi.encodePacked(name))] = false;
        pendingNameTransfers[msg.sender] = "";
        emit NameTransferAccepted(msg.sender, name);
    }

    function withdraw() public onlyAuthorized {
        owner.transfer(address(this).balance);
    }

    function keccak256String(string memory input) internal pure returns (bytes32) {
        bytes memory temp = bytes(input);
        if (temp.length == 0) {
            return 0x0;
        }
        assembly {
            let result := mload(add(input, 32))
            return(result)
        }
    }
}
```