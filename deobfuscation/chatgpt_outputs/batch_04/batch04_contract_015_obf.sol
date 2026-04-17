pragma solidity ^0.4.7;

contract Ownership {
    address public owner;
    bool public isLocked;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

    modifier notLocked() {
        require(isLocked == false, "contract is currently locked");
        _;
    }

    modifier noContract() {
        address sender = msg.sender;
        uint codeLength;
        assembly {
            codeLength := extcodesize(sender)
        }
        require(codeLength <= 0, "address must not be a contract");
        require(msg.sender == tx.origin, "msg.sender must equal tx.origin");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function setLockStatus(bool lockStatus) public onlyOwner {
        require(isLocked != lockStatus, "new status must be different from old status");
        isLocked = lockStatus;
    }
}

contract Registry {
    mapping(bytes32 => address) public nameToAddress;
    mapping(address => bytes32) public addressToName;

    function register(bytes32 name) public payable notLocked noContract {
        require(msg.value == 0, "No ether required");
        require(checkRegistration(msg.sender, name) == 0, "name or address already registered");
        nameToAddress[name] = msg.sender;
        addressToName[msg.sender] = name;
    }

    function checkRegistration(address addr, bytes32 name) public view returns (uint8) {
        if (nameToAddress[name] != address(0)) {
            return 1;
        }
        if (addressToName[addr] != 0) {
            return 2;
        }
        return 0;
    }

    function getAddress(bytes32 name) public view returns (address) {
        return nameToAddress[name];
    }
}