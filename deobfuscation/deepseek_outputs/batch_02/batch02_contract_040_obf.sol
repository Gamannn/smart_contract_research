pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    address public acceptableAddress;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AcceptableAddressChanged(address indexed previousAcceptable, address indexed newAcceptable);
    
    function Ownable() public {
        owner = msg.sender;
        acceptableAddress = address(0);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAcceptable() {
        require(msg.sender == acceptableAddress);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function setAcceptableAddress(address newAcceptable) public onlyOwner {
        require(newAcceptable != address(0));
        AcceptableAddressChanged(acceptableAddress, newAcceptable);
        acceptableAddress = newAcceptable;
    }
}

contract StorageContract is Ownable {
    mapping(bytes32 => uint) public uintStorage;
    mapping(bytes32 => string) public stringStorage;
    mapping(bytes32 => address) public addressStorage;
    mapping(bytes32 => bytes) public bytesStorage;
    mapping(bytes32 => bytes32) public bytes32Storage;
    mapping(bytes32 => bool) public boolStorage;
    mapping(bytes32 => int) public intStorage;
    
    function () public payable {
        require(msg.sender == acceptableAddress || msg.sender == owner);
    }
    
    function getUint(bytes32 key) public view returns (uint) {
        return uintStorage[key];
    }
    
    function setUint(bytes32 key, uint value) public onlyAcceptable {
        uintStorage[key] = value;
    }
    
    function getString(bytes32 key) public view returns (string) {
        return stringStorage[key];
    }
    
    function setString(bytes32 key, string value) public onlyAcceptable {
        stringStorage[key] = value;
    }
    
    function getAddress(bytes32 key) public view returns (address) {
        return addressStorage[key];
    }
    
    function setAddress(bytes32 key, address value) public onlyAcceptable {
        addressStorage[key] = value;
    }
    
    function getBytes(bytes32 key) public view returns (bytes) {
        return bytesStorage[key];
    }
    
    function setBytes(bytes32 key, bytes value) public onlyAcceptable {
        bytesStorage[key] = value;
    }
    
    function getBytes32(bytes32 key) public view returns (bytes32) {
        return bytes32Storage[key];
    }
    
    function setBytes32(bytes32 key, bytes32 value) public onlyAcceptable {
        bytes32Storage[key] = value;
    }
    
    function getBool(bytes32 key) public view returns (bool) {
        return boolStorage[key];
    }
    
    function setBool(bytes32 key, bool value) public onlyAcceptable {
        boolStorage[key] = value;
    }
    
    function getInt(bytes32 key) public view returns (int) {
        return intStorage[key];
    }
    
    function setInt(bytes32 key, int value) public onlyAcceptable {
        intStorage[key] = value;
    }
    
    function getBalance() public constant returns (uint) {
        return this.balance;
    }
    
    function withdraw(address recipient) public onlyAcceptable {
        bytes32 key = keccak256(recipient, "balance");
        uint amount = getUint(key);
        setUint(key, 0);
        recipient.transfer(amount);
    }
}