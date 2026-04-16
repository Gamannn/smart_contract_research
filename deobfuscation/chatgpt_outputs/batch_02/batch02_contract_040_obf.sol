pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    address public authorizedAddress;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
        authorizedAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == authorizedAddress);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setAuthorizedAddress(address newAuthorizedAddress) public onlyOwner {
        require(newAuthorizedAddress != address(0));
        authorizedAddress = newAuthorizedAddress;
    }
}

contract DataStorage is Ownable {
    mapping(bytes32 => uint) public uintStorage;
    mapping(bytes32 => string) public stringStorage;
    mapping(bytes32 => address) public addressStorage;
    mapping(bytes32 => bytes) public bytesStorage;
    mapping(bytes32 => bytes32) public bytes32Storage;
    mapping(bytes32 => bool) public boolStorage;
    mapping(bytes32 => int) public intStorage;

    function () public payable {
        require(msg.sender == authorizedAddress);
    }

    function getUint(bytes32 key) public view returns (uint) {
        return uintStorage[key];
    }

    function setUint(bytes32 key, uint value) public onlyAuthorized {
        uintStorage[key] = value;
    }

    function getString(bytes32 key) public view returns (string) {
        return stringStorage[key];
    }

    function setString(bytes32 key, string value) public onlyAuthorized {
        stringStorage[key] = value;
    }

    function getAddress(bytes32 key) public view returns (address) {
        return addressStorage[key];
    }

    function setAddress(bytes32 key, address value) public onlyAuthorized {
        addressStorage[key] = value;
    }

    function getBytes(bytes32 key) public view returns (bytes) {
        return bytesStorage[key];
    }

    function setBytes(bytes32 key, bytes value) public onlyAuthorized {
        bytesStorage[key] = value;
    }

    function getBytes32(bytes32 key) public view returns (bytes32) {
        return bytes32Storage[key];
    }

    function setBytes32(bytes32 key, bytes32 value) public onlyAuthorized {
        bytes32Storage[key] = value;
    }

    function getBool(bytes32 key) public view returns (bool) {
        return boolStorage[key];
    }

    function setBool(bytes32 key, bool value) public onlyAuthorized {
        boolStorage[key] = value;
    }

    function getInt(bytes32 key) public view returns (int) {
        return intStorage[key];
    }

    function setInt(bytes32 key, int value) public onlyAuthorized {
        intStorage[key] = value;
    }

    function getBalance() public constant returns (uint) {
        return this.balance;
    }

    function withdraw(address to) public onlyAuthorized {
        uint amount = getUint(keccak256(to, "balance"));
        setUint(keccak256(to, "balance"), 0);
        to.transfer(amount);
    }
}