```solidity
pragma solidity ^0.4.7;

contract BR {
    address public owner;
    bool public isLocked;
    uint256 public registrationFee;
    
    mapping(bytes32 => address) public nameToAddress;
    mapping(address => bytes32) public addressToName;
    
    string[] private errorMessages;
    
    constructor() public {
        owner = msg.sender;
        isLocked = false;
        registrationFee = 10000000000000000;
        
        errorMessages = [
            "update new status == old status",
            "msg.sender must equal tx.origin",
            "contract current is lock status",
            "address must not be contract",
            "current name has been used or current address has been one name",
            "only owner can call this function"
        ];
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, errorMessages[5]);
        _;
    }
    
    modifier notLocked() {
        require(isLocked == false, errorMessages[2]);
        _;
    }
    
    modifier notContract() {
        address sender = msg.sender;
        uint256 size;
        assembly {
            size := extcodesize(sender)
        }
        require(size <= 0, errorMessages[3]);
        require(msg.sender == tx.origin, errorMessages[1]);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function updateLockStatus(bool newStatus) onlyOwner public {
        require(isLocked != newStatus, errorMessages[0]);
        isLocked = newStatus;
    }
    
    function registerName(bytes32 name) notLocked notContract public payable {
        require(msg.value == registrationFee, "Incorrect fee");
        require(checkRegistration(msg.sender, name) == 0, errorMessages[4]);
        
        nameToAddress[name] = msg.sender;
        addressToName[msg.sender] = name;
    }
    
    function checkRegistration(address user, bytes32 name) public view returns (uint8) {
        if (nameToAddress[name] != address(0)) {
            return 1;
        }
        if (addressToName[user] != 0) {
            return 2;
        }
        return 0;
    }
    
    function getNameOwner(bytes32 name) public view returns (address) {
        return nameToAddress[name];
    }
}
```