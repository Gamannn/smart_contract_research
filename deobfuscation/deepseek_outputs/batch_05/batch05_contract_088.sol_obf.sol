pragma solidity ^0.4.7;

contract Ownable {
    address public owner;
    bool public isLocked;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

    modifier notLocked() {
        require(isLocked == false, "contract current is lock status");
        _;
    }

    modifier noContract() {
        address addr = msg.sender;
        uint size;
        assembly { size := extcodesize(addr) }
        require(size <= 0, "address must is not contract");
        require(msg.sender == tx.origin, "msg.sender must equipt tx.origin");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function setLockStatus(bool newStatus) public onlyOwner {
        require(isLocked != newStatus, "new status == old status");
        isLocked = newStatus;
    }

    function transferToOwner() public onlyOwner noContract {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
        emit TransferToOwner(owner, balance);
    }

    event TransferToOwner(address indexed owner, uint256 amount);
}

interface INameRegistry {
    function checkName(address addr, bytes32 name) public view returns (uint8);
    function getAddressByName(bytes32 name) public view returns (address);
    function getNameByAddress(address addr) public view returns (bytes32);
}

contract InvitationSystem is Ownable {
    uint256 public price = 10 finney;
    INameRegistry public nameRegistry;
    mapping(bytes32 => address) public nameToAddress;
    mapping(address => bytes32) public addressToName;

    constructor(INameRegistry registry) public {
        nameRegistry = INameRegistry(registry);
    }

    event CreateInviteNameEvent(address indexed user, bytes32 name);

    function createInviteName(bytes32 name) public payable notLocked noContract {
        require(msg.value == price, "incorrect payment");
        require(checkName(msg.sender, name) == 0, "current name has been used or current address has been one name");
        nameToAddress[name] = msg.sender;
        addressToName[msg.sender] = name;
        emit CreateInviteNameEvent(msg.sender, name);
    }

    function checkName(address addr, bytes32 name) public view returns (uint8) {
        if (nameToAddress[name] != address(0)) {
            return 1;
        }
        if (addressToName[addr] != 0) {
            return 2;
        }
        uint8 registryResult = nameRegistry.checkName(addr, name);
        if (registryResult != 0) {
            return registryResult;
        }
        return 0;
    }

    function getAddressByName(bytes32 name) public view returns (address) {
        address registryAddress = nameRegistry.getAddressByName(name);
        if (registryAddress != address(0)) {
            return registryAddress;
        }
        return nameToAddress[name];
    }

    function getNameByAddress(address addr) public view returns (bytes32) {
        bytes32 registryName = nameRegistry.getNameByAddress(addr);
        if (registryName != 0) {
            return registryName;
        }
        return addressToName[addr];
    }
}